const std = @import("std");
const virtio = @import("virtio.zig");
const virtio_mmio = @import("virtio_mmio.zig");
const root = @import("root");
const c = root.c;
const io = @import("io.zig");
const irq = @import("irq.zig");
const mem = std.mem;
const log = std.log;
const fs = std.fs;
const kvm = @import("root").kvm;
const os = std.os;
const Thread = std.Thread;
const ioctl = os.linux.ioctl;
const check = @import("helpers.zig").check_non_zero;

var allocator: mem.Allocator = undefined;
var tap_f: ?fs.File = null;
var vhost_f: ?fs.File = null;

const use_packed = false;

pub fn init(alloc: std.mem.Allocator) !void {
    const irq_line = irq.alloc();
    allocator = alloc;

    const device_features =
        (1 << virtio.c.VIRTIO_NET_F_CTRL_VQ) |
        (1 << virtio.c.VIRTIO_NET_F_CSUM) |
        (1 << virtio.c.VIRTIO_NET_F_HOST_TSO4) |
        (1 << virtio.c.VIRTIO_NET_F_HOST_TSO6) |
        (1 << virtio.c.VIRTIO_NET_F_GUEST_TSO4) |
        (1 << virtio.c.VIRTIO_NET_F_GUEST_TSO6) |
        (1 << virtio.c.VIRTIO_NET_F_MRG_RXBUF) |
        (1 << virtio.c.VIRTIO_RING_F_EVENT_IDX) |
        (1 << virtio.c.VIRTIO_RING_F_INDIRECT_DESC) |
        (1 << virtio.c.VIRTIO_F_VERSION_1) |
        (1 << virtio.c.VIRTIO_F_ANY_LAYOUT) |
        if (use_packed) (1 << virtio.c.VIRTIO_F_RING_PACKED) else 0;

    const dev = try virtio_mmio.register_net_dev(alloc, irq_line, mmio_rw);
    dev.set_device_features(device_features);
    dev.set_queue_init_proc(init_queue);

    try init_vhost();

    try create_tap();
}

fn init_vhost() !void {
    const ram = kvm.getMem();

    vhost_f = try fs.cwd().openFile("/dev/vhost-net", .{
        .mode = .read_write,
    });
    errdefer vhost_f.?.close();

    var mem_regions: extern struct {
        mem: virtio.c.vhost_memory,
        regions: [1]virtio.c.vhost_memory_region,
    } = .{
        .mem = .{ .nregions = 1, .padding = 0 },
        .regions = [_]virtio.c.vhost_memory_region{.{
            .guest_phys_addr = 0,
            .memory_size = ram.len,
            .userspace_addr = @intFromPtr(ram.ptr),
            .flags_padding = 0,
        }},
    };

    try check(ioctl(vhost_f.?.handle, virtio.c.VHOST_SET_OWNER, 0));
    try check(ioctl(vhost_f.?.handle, virtio.c.VHOST_SET_MEM_TABLE, @intFromPtr(&mem_regions)));

    const features: u64 =
        (1 << virtio.c.VIRTIO_RING_F_EVENT_IDX) |
        (1 << virtio.c.VIRTIO_NET_F_MRG_RXBUF);
    try check(ioctl(vhost_f.?.handle, virtio.c.VHOST_SET_FEATURES, @intFromPtr(&features)));
}

fn create_tap() !void {
    tap_f = try fs.cwd().openFile("/dev/net/tun", .{
        .mode = .read_write,
    });
    errdefer tap_f.?.close();

    var ifr = mem.zeroes(c.ifreq);
    ifr.ifr_ifru.ifru_flags = c.IFF_TAP | c.IFF_NO_PI | c.IFF_VNET_HDR;
    try check(ioctl(tap_f.?.handle, c.TUNSETIFF, @intFromPtr(&ifr)));

    try check(ioctl(tap_f.?.handle, c.TUNSETOFFLOAD, c.TUN_F_CSUM | c.TUN_F_TSO4 | c.TUN_F_TSO6));

    const hdr_len: c_int = @sizeOf(virtio.c.virtio_net_hdr_mrg_rxbuf);
    try check(ioctl(tap_f.?.handle, c.TUNSETVNETHDRSZ, @intFromPtr(&hdr_len)));

    const ipaddr = try std.net.Address.parseIp4("192.168.66.1", 0);
    const sock = try os.socket(ipaddr.any.family, os.SOCK.DGRAM, 0);
    defer os.close(sock);

    // set ip addr
    ifr.ifr_ifru.ifru_addr.sa_family = ipaddr.any.family;
    ifr.ifr_ifru.ifru_addr.sa_data = ipaddr.any.data;
    try check(ioctl(sock, c.SIOCSIFADDR, @intFromPtr(&ifr)));

    // link up
    try check(ioctl(sock, c.SIOCGIFFLAGS, @intFromPtr(&ifr)));
    ifr.ifr_ifru.ifru_flags |= @intCast(c.IFF_UP | c.IFF_RUNNING);
    try check(ioctl(sock, c.SIOCSIFFLAGS, @intFromPtr(&ifr)));

    log.info("net: use {s}", .{ifr.ifr_ifrn.ifrn_name});
}

fn init_queue(dev: *virtio_mmio.Dev, q: *virtio.Q) !void {
    for (&dev.vqs, 0..) |*vq, i| {
        if (@intFromPtr(vq) == @intFromPtr(q)) {
            switch (i) {
                0, 1 => {
                    // setup vhost for rx/tx queue
                    var state: virtio.c.vhost_vring_state = .{
                        .index = @intCast(i),
                        .num = q.size,
                    };
                    try check(ioctl(vhost_f.?.handle, virtio.c.VHOST_SET_VRING_NUM, @intFromPtr(&state)));

                    state.num = 0;
                    try check(ioctl(vhost_f.?.handle, virtio.c.VHOST_SET_VRING_BASE, @intFromPtr(&state)));

                    const addr: virtio.c.vhost_vring_addr = .{
                        .index = @intCast(i),
                        .desc_user_addr = @intFromPtr(q.ring.split.ring.desc),
                        .avail_user_addr = @intFromPtr(q.ring.split.ring.avail),
                        .used_user_addr = @intFromPtr(q.ring.split.ring.used),
                        .flags = 0,
                        .log_guest_addr = 0,
                    };
                    try check(ioctl(vhost_f.?.handle, virtio.c.VHOST_SET_VRING_ADDR, @intFromPtr(&addr)));

                    var file: virtio.c.vhost_vring_file = .{
                        .index = @intCast(i),
                        .fd = q.eventfd.handle,
                    };
                    try check(ioctl(vhost_f.?.handle, virtio.c.VHOST_SET_VRING_KICK, @intFromPtr(&file)));

                    const eventfd = try std.os.eventfd(0, 0);

                    const handle = try Thread.spawn(.{}, call_poll, .{ dev, eventfd });
                    handle.detach();

                    file.fd = eventfd;
                    try check(ioctl(vhost_f.?.handle, virtio.c.VHOST_SET_VRING_CALL, @intFromPtr(&file)));

                    file.fd = tap_f.?.handle;
                    try check(ioctl(vhost_f.?.handle, virtio.c.VHOST_NET_SET_BACKEND, @intFromPtr(&file)));
                },
                2 => {
                    // polling for ctrl queue
                    const handle = try Thread.spawn(.{}, ctrl_io, .{ dev, q });
                    handle.detach();
                },
                else => unreachable,
            }
            break;
        }
    } else unreachable;
}

fn call_poll(dev: *virtio_mmio.Dev, eventfd: os.fd_t) !void {
    const f: fs.File = .{
        .handle = eventfd,
        .capable_io_mode = .blocking,
        .intended_io_mode = .blocking,
    };
    const reader = f.reader();
    while (true) {
        const n = try reader.readIntNative(u64);
        if (n > 0) {
            try dev.assert_ring_irq();
        }
    }
}

fn ctrl_io(dev: *virtio_mmio.Dev, q: *virtio.Q) !void {
    const ram = kvm.getMem();

    while (true) {
        try q.waitAvail();
        while (q.getAvail()) |desc0| {
            var len: usize = 0;
            var cur = q.getNext(desc0).?;

            while (q.getNext(cur)) |next| : (cur = next) {
                len += cur.desc.len;
            }

            ram[cur.desc.addr] = virtio.c.VIRTIO_NET_OK;

            q.putUsed(.{
                .id = desc0.id,
                .len = @as(c_uint, @intCast(len)),
            });
        }

        // notfiy guest if needed
        if (q.need_notify()) {
            try dev.assert_ring_irq();
        }
    }
}

pub fn deinit() void {
    if (tap_f) |f| f.close();
    if (vhost_f) |f| f.close();
}

var config = mem.zeroInit(virtio.c.virtio_net_config, .{
    .status = virtio.c.VIRTIO_NET_S_LINK_UP,
    .max_virtqueue_pairs = 1,
});

fn mmio_rw(_: *virtio_mmio.Dev, offset: u64, op: io.Operation, data: []u8) anyerror!void {
    if (offset + data.len <= @sizeOf(@TypeOf(config))) {
        const ptr: [*]u8 = @ptrCast(&config);
        switch (op) {
            .Read => @memcpy(data, (ptr + offset)[0..data.len]),
            .Write => @memcpy((ptr + offset)[0..data.len], data),
        }
    } else {
        log.debug("unhandled offset: 0x{x} {} {any}", .{ offset, op, data });
        unreachable;
    }
}
