const std = @import("std");
const virtio = @import("virtio.zig");
const virtio_mmio = @import("virtio_mmio.zig");
const io = @import("io.zig");
const irq = @import("irq.zig");
const c = @cImport({
    @cInclude("linux/virtio_mmio.h");
    @cInclude("linux/virtio_ids.h");
    @cInclude("linux/virtio_blk.h");
    @cInclude("linux/virtio_ring.h");
});
const mem = std.mem;
const log = std.log;
const fs = std.fs;
const Thread = std.Thread;
const kvm = @import("root").kvm;
const os = std.os;

var addr: u64 = undefined;
var allocator: mem.Allocator = undefined;
var disk_file_path: []const u8 = undefined;
var irq_line: u8 = undefined;

pub fn init(alloc: std.mem.Allocator, path: []const u8) !void {
    irq_line = irq.alloc();
    addr = try virtio_mmio.register_dev(alloc, irq_line, mmio_rw);
    allocator = alloc;
    disk_file_path = path;

    const stat = try fs.cwd().statFile(path);
    config.capacity = stat.size / 512;
}

fn blkio(q: *virtio.Q) !void {
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
                .len = @truncate(len),
            });
        }
        // notfiy guest if needed
        if (q.need_notify()) {
            irq_status |= c.VIRTIO_MMIO_INT_VRING;
            try kvm.triggerIrq(irq_line);
        }
    }
}

pub fn deinit() void {}

const device_features = (1 << c.VIRTIO_BLK_F_FLUSH) | (1 << c.VIRTIO_RING_F_EVENT_IDX) | (1 << c.VIRTIO_RING_F_INDIRECT_DESC);
var status: u32 = undefined;
var feature_sel: u32 = undefined;
var driver_feature_sel: u32 = undefined;
var driver_features: u64 = undefined;
var vqs: [1]?virtio.Q = .{null};
var q_size: u32 = undefined;
var q_align: u32 = undefined;
var q_sel: u32 = undefined;
var q_page_sz: ?u32 = null;
var config: c.virtio_blk_config = mem.zeroes(c.virtio_blk_config);
var irq_status: u32 = 0;

fn mmio_rw(offset: u64, op: io.Operation, len: u32, data: []u8) anyerror!void {
    switch (offset) {
        c.VIRTIO_MMIO_MAGIC_VALUE => if (op == .Read) {
            @memcpy(data.ptr, "virt");
        } else unreachable,
        c.VIRTIO_MMIO_VERSION => if (op == .Read) {
            mem.writeIntLittle(u32, data[0..4], 1);
        } else unreachable,
        c.VIRTIO_MMIO_DEVICE_ID => if (op == .Read) {
            mem.writeIntLittle(u32, data[0..4], c.VIRTIO_ID_BLOCK);
        } else unreachable,
        c.VIRTIO_MMIO_VENDOR_ID => if (op == .Read) {
            mem.writeIntLittle(u32, data[0..4], 0x12345678);
        } else unreachable,
        c.VIRTIO_MMIO_STATUS => switch (op) {
            .Read => mem.writeIntLittle(u32, data[0..4], status),
            .Write => status = mem.readIntLittle(u32, data[0..4]),
        },
        c.VIRTIO_MMIO_DEVICE_FEATURES_SEL => switch (op) {
            .Read => unreachable,
            .Write => feature_sel = mem.readIntLittle(u32, data[0..4]),
        },
        c.VIRTIO_MMIO_DEVICE_FEATURES => switch (op) {
            .Read => mem.writeIntLittle(u32, data[0..4], if (feature_sel == 0) device_features else @as(u32, 0)),
            .Write => unreachable,
        },
        c.VIRTIO_MMIO_DRIVER_FEATURES_SEL => switch (op) {
            .Read => unreachable,
            .Write => driver_feature_sel = mem.readIntLittle(u32, data[0..4]),
        },
        c.VIRTIO_MMIO_GUEST_PAGE_SIZE => switch (op) {
            .Read => unreachable,
            .Write => q_page_sz = mem.readIntLittle(u32, data[0..4]),
        },
        c.VIRTIO_MMIO_DRIVER_FEATURES => switch (op) {
            .Read => unreachable,
            .Write => switch (driver_feature_sel) {
                0 => driver_features |= mem.readIntLittle(u32, data[0..4]),
                1 => driver_features |= @as(u64, mem.readIntLittle(u32, data[0..4])) << 32,
                else => unreachable,
            },
        },
        c.VIRTIO_MMIO_QUEUE_NUM_MAX => switch (op) {
            .Read => mem.writeIntLittle(u32, data[0..4], 256),
            .Write => unreachable,
        },
        c.VIRTIO_MMIO_QUEUE_SEL => switch (op) {
            .Read => unreachable,
            .Write => q_sel = mem.readIntLittle(u32, data[0..4]),
        },

        c.VIRTIO_MMIO_QUEUE_NUM => switch (op) {
            .Read => unreachable,
            .Write => q_size = mem.readIntLittle(u32, data[0..4]),
        },
        c.VIRTIO_MMIO_QUEUE_ALIGN => switch (op) {
            .Read => unreachable,
            .Write => q_align = mem.readIntLittle(u32, data[0..4]),
        },
        c.VIRTIO_MMIO_QUEUE_PFN => switch (op) {
            .Read => if (vqs[q_sel]) |q| {
                mem.writeIntLittle(u32, data[0..4], q.pfn);
            } else mem.writeInt(u32, data[0..4], 0, .Little),
            .Write => {
                const pfn = mem.readIntLittle(u32, data[0..4]);
                if (pfn > 0) {
                    vqs[q_sel] = try virtio.Q.init(pfn, q_size, q_align, driver_features, q_page_sz);
                    const handle = try Thread.spawn(.{}, blkio, .{&vqs[q_sel].?});
                    handle.detach();
                } else {
                    vqs[q_sel].?.deinit();
                }
            },
        },
        c.VIRTIO_MMIO_QUEUE_NOTIFY => switch (op) {
            .Read => unreachable,
            .Write => {
                const i = mem.readIntLittle(u32, data[0..4]);
                try vqs[i].?.notifyAvail();
            },
        },
        c.VIRTIO_MMIO_INTERRUPT_STATUS => switch (op) {
            .Read => mem.writeIntLittle(u32, data[0..4], irq_status),
            .Write => unreachable,
        },
        c.VIRTIO_MMIO_INTERRUPT_ACK => switch (op) {
            .Read => unreachable,
            .Write => irq_status &= ~(mem.readIntLittle(u32, data[0..4])),
        },
        else => if (offset >= c.VIRTIO_MMIO_CONFIG) {
            const off = offset - c.VIRTIO_MMIO_CONFIG;
            const ptr: [*]u8 = @ptrCast(&config);
            std.debug.assert(len == 1);
            switch (op) {
                .Read => data[0] = (ptr + off)[0],
                .Write => (ptr + off)[0] = data[0],
            }
        } else {
            log.warn("unhandle {} 0x{x}, len[{}], 0x{x}\n", .{ op, offset, len, mem.readIntLittle(u32, data[0..4]) });
        },
    }
}
