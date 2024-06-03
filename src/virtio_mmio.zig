const std = @import("std");
const io = @import("io.zig");
const mmio = @import("mmio.zig");
const virtio = @import("virtio.zig");
const fmt = std.fmt;
pub const c = @cImport({
    @cInclude("linux/virtio_mmio.h");
});
const mem = std.mem;
const kvm = @import("root").kvm;

const IO_SIZE = 0x200;
const Kind = enum {
    blk,
    net,
};

pub const Dev = struct {
    const Self = @This();
    const Handler = *const fn (*Self, u64, io.Operation, []u8) anyerror!void;

    name: [32]u8 = undefined,
    irq: u32,
    start: u64,
    len: u64,
    specific_handler: Handler,
    kind: Kind,

    status: u32 = undefined,
    feature_sel: u32 = undefined,
    driver_feature_sel: u32 = undefined,
    driver_features: u64 = 0,
    device_features: u64 = 0,
    vqs: [256]?virtio.Q = .{null} ** 256,
    q_size: u32 = undefined,
    q_align: u32 = undefined,
    q_sel: u32 = undefined,
    q_page_sz: ?u32 = null,
    irq_status: u32 = 0,
    init_queue_proc: *const fn (dev: *Self, q: *virtio.Q) anyerror!void = undefined,
    not_support_ioeventfd: bool = false,

    // v2 only
    descs_addr: u64 = undefined,
    avail_addr: u64 = undefined,
    used_addr: u64 = undefined,

    pub fn init(self: *Self, kind: Kind, name: []const u8, irq: u32, start: u64, len: u64, h: Handler) !void {
        try mmio.register_handler(start, len, handler, self);

        const dev: Self = .{
            .irq = irq,
            .start = start,
            .len = len,
            .specific_handler = h,
            .kind = kind,
        };
        self.* = dev;
        @memcpy(self.name[0..name.len], name);
    }

    pub fn deinit(_: *Self) void {}

    pub fn set_device_features(self: *Self, features: u64) void {
        self.device_features = features;
    }

    pub fn set_queue_init_proc(self: *Self, init_fn: *const fn (dev: *Self, q: *virtio.Q) anyerror!void) void {
        self.init_queue_proc = init_fn;
    }

    fn update_irq(self: *const Self) !void {
        if (self.irq_status != 0) {
            try kvm.setIrqLevel(self.irq, 1);
        } else {
            try kvm.setIrqLevel(self.irq, 0);
        }
    }

    pub fn assert_ring_irq(self: *Self, _: *const virtio.Q) !void {
        self.irq_status |= c.VIRTIO_MMIO_INT_VRING;
        try self.update_irq();
    }

    pub fn get_msix_irq(_: *const Self, _: *const virtio.Q) ?u32 {
        return null;
    }

    pub fn handler(ctx: ?*anyopaque, offset: u64, op: io.Operation, data: []u8) anyerror!void {
        var self: *Self = @alignCast(@ptrCast(ctx));
        switch (offset) {
            c.VIRTIO_MMIO_MAGIC_VALUE => if (op == .Read) {
                @memcpy(data.ptr, "virt");
            } else unreachable,
            c.VIRTIO_MMIO_VERSION => if (op == .Read) {
                mem.writeInt(u32, data[0..4], 2, .little);
            } else unreachable,
            c.VIRTIO_MMIO_VENDOR_ID => if (op == .Read) {
                mem.writeInt(u32, data[0..4], 0x12345678, .little);
            } else unreachable,
            c.VIRTIO_MMIO_DEVICE_ID => if (op == .Read) {
                mem.writeInt(i32, data[0..4], switch (self.kind) {
                    .blk => virtio.c.VIRTIO_ID_BLOCK,
                    .net => virtio.c.VIRTIO_ID_NET,
                }, .little);
            } else unreachable,
            c.VIRTIO_MMIO_STATUS => switch (op) {
                .Read => mem.writeInt(u32, data[0..4], self.status, .little),
                .Write => self.status = mem.readInt(u32, data[0..4], .little),
            },
            c.VIRTIO_MMIO_DEVICE_FEATURES_SEL => switch (op) {
                .Read => unreachable,
                .Write => self.feature_sel = mem.readInt(u32, data[0..4], .little),
            },
            c.VIRTIO_MMIO_DEVICE_FEATURES => switch (op) {
                .Read => mem.writeInt(u32, data[0..4], if (self.feature_sel == 0) @as(u32, @truncate(self.device_features)) else @as(u32, @truncate(self.device_features >> 32)), .little),
                .Write => unreachable,
            },
            c.VIRTIO_MMIO_DRIVER_FEATURES_SEL => switch (op) {
                .Read => unreachable,
                .Write => self.driver_feature_sel = mem.readInt(u32, data[0..4], .little),
            },
            c.VIRTIO_MMIO_GUEST_PAGE_SIZE => switch (op) {
                .Read => unreachable,
                .Write => self.q_page_sz = mem.readInt(u32, data[0..4], .little),
            },
            c.VIRTIO_MMIO_DRIVER_FEATURES => switch (op) {
                .Read => unreachable,
                .Write => switch (self.driver_feature_sel) {
                    0 => self.driver_features |= mem.readInt(u32, data[0..4], .little),
                    1 => self.driver_features |= @as(u64, mem.readInt(u32, data[0..4], .little)) << 32,
                    else => unreachable,
                },
            },
            c.VIRTIO_MMIO_QUEUE_NUM_MAX => switch (op) {
                .Read => mem.writeInt(u32, data[0..4], 256, .little),
                .Write => unreachable,
            },
            c.VIRTIO_MMIO_QUEUE_SEL => switch (op) {
                .Read => unreachable,
                .Write => self.q_sel = mem.readInt(u32, data[0..4], .little),
            },

            c.VIRTIO_MMIO_QUEUE_NUM => switch (op) {
                .Read => unreachable,
                .Write => self.q_size = mem.readInt(u32, data[0..4], .little),
            },
            c.VIRTIO_MMIO_QUEUE_ALIGN => switch (op) {
                .Read => unreachable,
                .Write => self.q_align = mem.readInt(u32, data[0..4], .little),
            },
            c.VIRTIO_MMIO_QUEUE_PFN => switch (op) {
                .Read => if (self.vqs[self.q_sel]) |q| {
                    mem.writeInt(u32, data[0..4], q.ring.split.pfn.?, .little);
                } else mem.writeInt(u32, data[0..4], 0, .little),
                .Write => {
                    const pfn = mem.readInt(u32, data[0..4], .little);
                    if (pfn > 0) {
                        const i = self.q_sel;
                        const eventfd = try std.posix.eventfd(0, 0);
                        kvm.addIOEventFd(self.start + c.VIRTIO_MMIO_QUEUE_NOTIFY, 4, eventfd, i) catch {
                            self.not_support_ioeventfd = true;
                        };
                        const q = try virtio.Q.init(.{ .v1 = .{ .pfn = pfn } }, self.q_size, self.q_align, self.driver_features, self.q_page_sz, eventfd);

                        self.vqs[i] = q;
                        try self.init_queue_proc(self, &self.vqs[self.q_sel].?);
                    } else {
                        self.vqs[self.q_sel].?.deinit();
                    }
                },
            },
            c.VIRTIO_MMIO_QUEUE_NOTIFY => switch (op) {
                .Read => unreachable,
                .Write => if (self.not_support_ioeventfd) {
                    const i = mem.readInt(u32, data[0..4], .little);
                    try self.vqs[i].?.notifyAvail();
                } else unreachable,
            },
            c.VIRTIO_MMIO_INTERRUPT_STATUS => switch (op) {
                .Read => mem.writeInt(u32, data[0..4], self.irq_status, .little),
                .Write => unreachable,
            },
            c.VIRTIO_MMIO_INTERRUPT_ACK => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.irq_status &= ~(mem.readInt(u32, data[0..4], .little));
                    try self.update_irq();
                },
            },
            c.VIRTIO_MMIO_QUEUE_DESC_LOW => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.descs_addr &= 0xffffffff_00000000;
                    self.descs_addr |= mem.readInt(u32, data[0..4], .little);
                },
            },
            c.VIRTIO_MMIO_QUEUE_DESC_HIGH => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.descs_addr &= 0x00000000_ffffffff;
                    self.descs_addr |= (@as(u64, mem.readInt(u32, data[0..4], .little)) << 32);
                },
            },
            c.VIRTIO_MMIO_QUEUE_AVAIL_LOW => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.avail_addr &= 0xffffffff_00000000;
                    self.avail_addr |= mem.readInt(u32, data[0..4], .little);
                },
            },
            c.VIRTIO_MMIO_QUEUE_AVAIL_HIGH => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.avail_addr &= 0x00000000_ffffffff;
                    self.avail_addr |= (@as(u64, mem.readInt(u32, data[0..4], .little)) << 32);
                },
            },
            c.VIRTIO_MMIO_QUEUE_USED_LOW => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.used_addr &= 0xffffffff_00000000;
                    self.used_addr |= mem.readInt(u32, data[0..4], .little);
                },
            },
            c.VIRTIO_MMIO_QUEUE_USED_HIGH => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.used_addr &= 0x00000000_ffffffff;
                    self.used_addr |= (@as(u64, mem.readInt(u32, data[0..4], .little)) << 32);
                },
            },
            c.VIRTIO_MMIO_QUEUE_READY => switch (op) {
                .Read => if (self.vqs[self.q_sel]) |q| {
                    mem.writeInt(u32, data[0..4], @intFromBool(q.ring.pack.ready), .little);
                } else mem.writeInt(u32, data[0..4], 0, .little),
                .Write => {
                    const ready = mem.readInt(u32, data[0..4], .little);
                    if (ready > 0) {
                        const i = self.q_sel;
                        const eventfd = try std.posix.eventfd(0, 0);
                        kvm.addIOEventFd(self.start + c.VIRTIO_MMIO_QUEUE_NOTIFY, 4, eventfd, i) catch {
                            self.not_support_ioeventfd = true;
                        };
                        const q = try virtio.Q.init(.{ .v2 = .{
                            .descs_addr = self.descs_addr,
                            .avail_addr = self.avail_addr,
                            .used_addr = self.used_addr,
                        } }, self.q_size, self.q_align, self.driver_features, self.q_page_sz, eventfd);
                        self.vqs[i] = q;
                        try self.init_queue_proc(self, &self.vqs[self.q_sel].?);
                    } else {
                        self.vqs[self.q_sel].?.deinit();
                    }
                },
            },
            c.VIRTIO_MMIO_CONFIG_GENERATION => switch (op) {
                .Read => mem.writeInt(u32, data[0..4], 0, .little), // TODO: support version generation
                .Write => unreachable,
            },

            else => try self.specific_handler(self, offset - c.VIRTIO_MMIO_CONFIG, op, data),
        }
    }
};

const max_devs = 32;
var registered_devs: [max_devs]Dev = undefined;
var registered_num: usize = 0;

pub fn get_registered_devs() []Dev {
    return registered_devs[0..registered_num];
}

fn register_dev(kind: Kind, irq: u32, h: *const fn (*Dev, u64, io.Operation, []u8) anyerror!void) !*Dev {
    const addr = mmio.alloc_space(IO_SIZE);

    const pdev = &registered_devs[registered_num];
    var buf: [64]u8 = undefined;
    const name = try fmt.bufPrint(&buf, "virtio_mmio{}", .{registered_num});
    try pdev.init(kind, name, irq, addr, IO_SIZE, h);

    registered_num += 1;
    return pdev;
}

pub fn register_blk_dev(irq: u32, h: *const fn (*Dev, u64, io.Operation, []u8) anyerror!void) !*Dev {
    return register_dev(.blk, irq, h);
}
pub fn register_net_dev(irq: u32, h: *const fn (*Dev, u64, io.Operation, []u8) anyerror!void) !*Dev {
    return register_dev(.net, irq, h);
}
