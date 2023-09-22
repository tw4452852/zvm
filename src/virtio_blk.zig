const std = @import("std");
const virtio = @import("virtio.zig");
const virtio_mmio = @import("virtio_mmio.zig");
const c = virtio_mmio.c;
const io = @import("io.zig");
const irq = @import("irq.zig");
const mem = std.mem;
const log = std.log;
const fs = std.fs;
const kvm = @import("root").kvm;
const os = std.os;
const Thread = std.Thread;

var allocator: mem.Allocator = undefined;
var disk_file_path: []const u8 = undefined;
var irq_line: u8 = undefined;

pub fn init(alloc: std.mem.Allocator, path: []const u8) !void {
    irq_line = irq.alloc();
    allocator = alloc;
    disk_file_path = path;

    const device_features = (1 << c.VIRTIO_BLK_F_FLUSH) | (1 << c.VIRTIO_RING_F_EVENT_IDX) | (1 << c.VIRTIO_RING_F_INDIRECT_DESC) | (1 << c.VIRTIO_F_VERSION_1);
    const dev = try virtio_mmio.register_dev(alloc, irq_line, mmio_rw);
    dev.set_device_features(device_features);
    dev.set_queue_init_proc(init_queue);

    const stat = try fs.cwd().statFile(path);
    config.capacity = stat.size / 512;
}

fn init_queue(dev: *virtio_mmio.Dev, q: *virtio.Q) !void {
    const handle = try Thread.spawn(.{}, blkio, .{ dev, q });
    handle.detach();
}

fn blkio(dev: *virtio_mmio.Dev, q: *virtio.Q) !void {
    const ram = kvm.getMem();
    const f = try fs.cwd().openFile(disk_file_path, .{ .mode = .read_write });
    defer f.close();

    while (true) {
        try q.waitAvail();
        while (q.getAvail()) |desc0| {
            //log.info("{}: 0x{x}, {} 0x{x} {}\n", .{ desc0.id, desc0.desc.addr, desc0.desc.len, desc0.desc.flags, desc0.desc.next });
            std.debug.assert(desc0.desc.len == @sizeOf(c.virtio_blk_outhdr));
            const hdr: *const c.virtio_blk_outhdr = @alignCast(@ptrCast(ram.ptr + desc0.desc.addr));
            const off = hdr.sector * 512;
            const t = hdr.type;

            var cur = q.getNext(desc0).?;
            var len: usize = 0;
            switch (t) {
                c.VIRTIO_BLK_T_IN => {
                    var iovecs = std.ArrayList(os.iovec).init(allocator);
                    defer iovecs.deinit();

                    while (q.getNext(cur)) |next| {
                        try iovecs.append(.{ .iov_base = ram.ptr + cur.desc.addr, .iov_len = cur.desc.len });
                        cur = next;
                    }
                    len = try f.preadvAll(iovecs.items, off);
                },
                c.VIRTIO_BLK_T_OUT => {
                    var iovecs = std.ArrayList(os.iovec_const).init(allocator);
                    defer iovecs.deinit();
                    while (q.getNext(cur)) |next| {
                        try iovecs.append(.{ .iov_base = ram.ptr + cur.desc.addr, .iov_len = cur.desc.len });
                        len += cur.desc.len;
                        cur = next;
                    }
                    try f.pwritevAll(iovecs.items, off);
                },
                c.VIRTIO_BLK_T_FLUSH => try os.fsync(f.handle),
                else => unreachable,
            }
            // cur points to the status desc
            ram[cur.desc.addr] = c.VIRTIO_BLK_S_OK;

            //log.info("{} from:0x{x}, len:0x{x}\n", .{ t, off, @truncate(c_uint, len) });
            q.putUsed(.{
                .id = desc0.id,
                .len = @as(c_uint, @intCast(len)),
            });
        }
        // notfiy guest if needed
        if (q.need_notify()) {
            dev.irq_status |= c.VIRTIO_MMIO_INT_VRING;
            try dev.update_irq();
        }
    }
}

pub fn deinit() void {}

var config: c.virtio_blk_config = mem.zeroes(c.virtio_blk_config);

fn mmio_rw(_: *virtio_mmio.Dev, offset: u64, op: io.Operation, len: u32, data: []u8) anyerror!void {
    if (offset >= c.VIRTIO_MMIO_CONFIG) {
        const off = offset - c.VIRTIO_MMIO_CONFIG;
        const ptr: [*]u8 = @ptrCast(&config);
        switch (op) {
            .Read => @memcpy(data[0..len], (ptr + off)[0..len]),
            .Write => @memcpy((ptr + off)[0..len], data[0..len]),
        }
    } else {
        log.debug("unhandled offset: 0x{x} {}", .{ offset, op });
        unreachable;
    }
}
