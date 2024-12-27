const std = @import("std");
const pci = @import("pci.zig");
const io = @import("io.zig");
const kvm = @import("root").kvm;
const virtio = @import("virtio.zig");
const mem = std.mem;
const mmio = @import("mmio.zig");
const MSIX = @import("irq.zig").MSIX;
pub const c = @cImport({
    @cInclude("linux/virtio_pci.h");
});

pub const Dev = struct {
    const Self = @This();
    const Handler = *const fn (*Self, u64, io.Operation, []u8) anyerror!void;
    const max_queue_num = 64;

    const BAR0 = struct {
        cfg: c.virtio_pci_common_cfg,
        dev_cfg: [4096]u8,
        irq_status: u16,
        notify: u16,
    };

    const BAR1 = struct {
        queue_msix: [max_queue_num + 1]pci.msix_table_entry,
        pba: [max_queue_num + 1]u1,
    };

    const VQProperty = struct {
        size: u16,
        descs: u64,
        avail: u64,
        used: u64,
        msix_idx: ?usize,
        msix: ?MSIX,
    };

    irq: u32,
    device_feature: u64 = 0,
    driver_features: u64 = 0,
    specific_handler: Handler,
    pdev: *pci.Dev,
    init_queue_proc: *const fn (dev: *Self, q: *virtio.Q) anyerror!void = undefined,
    bar0: BAR0,
    bar1: BAR1,
    vqs: [max_queue_num]?virtio.Q = .{null} ** max_queue_num,
    vq_properties: [max_queue_num]VQProperty = .{VQProperty{ .size = 0, .descs = 0, .avail = 0, .used = 0, .msix_idx = null, .msix = null }} ** max_queue_num,
    not_support_ioeventfd: bool = false,
    global_msix_ctrl: *u16,

    pub fn init(self: *Self, irq: u32, vendor_id: u16, device_id: u16, subsys_vendor_id: u16, subsys_id: u16, class: u16, specific_handler: Handler) !void {
        const pdev = try pci.register(vendor_id, device_id, subsys_vendor_id, subsys_id, class, irq);

        // prepare bar0
        try pdev.allocate_bar(0, mem.alignForward(u64, @sizeOf(BAR0), 4096), handler0, self);

        // prepare bar1 for MSIX
        try pdev.allocate_bar(1, mem.alignForward(u64, @sizeOf(BAR1), 4096), handler1, self);

        // register common cfg capability for modern virtio pci device
        const comm_cfg: c.virtio_pci_cap = .{
            .cap_vndr = pci.c.PCI_CAP_ID_VNDR,
            .cap_next = 0,
            .cap_len = @sizeOf(c.virtio_pci_cap),
            .cfg_type = c.VIRTIO_PCI_CAP_COMMON_CFG,
            .bar = 0,
            .id = 0,
            .padding = .{ 0, 0 },
            .offset = mem.nativeToLittle(u32, @offsetOf(BAR0, "cfg")),
            .length = mem.nativeToLittle(u32, @sizeOf(@TypeOf(self.bar0.cfg))),
        };
        const cfg_cap = try pdev.add_cap(@TypeOf(comm_cfg));
        cfg_cap.* = comm_cfg;

        // register isr cfg capability for modern virtio pci device
        const isr_cfg: c.virtio_pci_cap = .{
            .cap_vndr = pci.c.PCI_CAP_ID_VNDR,
            .cap_next = 0,
            .cap_len = @sizeOf(c.virtio_pci_cap),
            .cfg_type = c.VIRTIO_PCI_CAP_ISR_CFG,
            .bar = 0,
            .id = 0,
            .padding = .{ 0, 0 },
            .offset = mem.nativeToLittle(u32, @offsetOf(BAR0, "irq_status")),
            .length = mem.nativeToLittle(u32, @sizeOf(@TypeOf(self.bar0.irq_status))),
        };
        const isr_cap = try pdev.add_cap(@TypeOf(isr_cfg));
        isr_cap.* = isr_cfg;

        // register notify cfg capability for modern virtio pci device
        const notify_cfg: c.virtio_pci_cap = .{
            .cap_vndr = pci.c.PCI_CAP_ID_VNDR,
            .cap_next = 0,
            .cap_len = @sizeOf(c.virtio_pci_cap),
            .cfg_type = c.VIRTIO_PCI_CAP_NOTIFY_CFG,
            .bar = 0,
            .id = 0,
            .padding = .{ 0, 0 },
            .offset = mem.nativeToLittle(u32, @offsetOf(BAR0, "notify")),
            .length = mem.nativeToLittle(u32, @sizeOf(@TypeOf(self.bar0.notify))),
        };
        const notify_cap = try pdev.add_cap(@TypeOf(notify_cfg));
        notify_cap.* = notify_cfg;

        // register device cfg capability for modern virtio pci device
        const dev_cfg: c.virtio_pci_cap = .{
            .cap_vndr = pci.c.PCI_CAP_ID_VNDR,
            .cap_next = 0,
            .cap_len = @sizeOf(c.virtio_pci_cap),
            .cfg_type = c.VIRTIO_PCI_CAP_DEVICE_CFG,
            .bar = 0,
            .id = 0,
            .padding = .{ 0, 0 },
            .offset = mem.nativeToLittle(u32, @offsetOf(BAR0, "dev_cfg")),
            .length = mem.nativeToLittle(u32, @sizeOf(virtio.c.virtio_blk_config)),
        };
        const dev_cap = try pdev.add_cap(@TypeOf(dev_cfg));
        dev_cap.* = dev_cfg;

        // register msix capability for modern virtio pci device
        const msix_cfg: pci.msix_cap = .{
            .cap_vndr = pci.c.PCI_CAP_ID_MSIX,
            .cap_next = 0,
            .ctrl = mem.nativeToLittle(u16, max_queue_num + 1 - 1), // number of msix table entries - 1
            .table_offset = mem.nativeToLittle(u32, 2),
            .pba_offset = mem.nativeToLittle(u32, @offsetOf(BAR1, "pba") | 2),
        };
        const msix_cap = try pdev.add_cap(@TypeOf(msix_cfg));
        msix_cap.* = msix_cfg;

        const dev: Self = .{
            .irq = irq,
            .pdev = pdev,
            .specific_handler = specific_handler,
            .bar0 = mem.zeroInit(BAR0, .{
                .cfg = mem.zeroInit(c.virtio_pci_common_cfg, .{
                    .num_queues = mem.nativeToLittle(u16, max_queue_num),
                    .queue_size = mem.nativeToLittle(u16, 256),
                }),
            }),
            .bar1 = mem.zeroes(BAR1),
            .global_msix_ctrl = &msix_cap.ctrl,
        };

        self.* = dev;
    }

    pub fn deinit(_: *Self) void {}

    pub fn set_device_features(self: *Self, features: u64) void {
        self.device_feature = features;
    }

    pub fn set_queue_init_proc(self: *Self, init_fn: *const fn (dev: *Self, q: *virtio.Q) anyerror!void) void {
        self.init_queue_proc = init_fn;
    }

    pub fn get_msix_irq(self: *const Self, q: *const virtio.Q) ?u32 {
        const i = (@intFromPtr(q) - @intFromPtr(&self.vqs)) / @sizeOf(@TypeOf(q.*));
        if (self.vq_properties[i].msix_idx) |msix_idx| {
            return self.bar1.queue_msix[msix_idx].data;
        }
        return null;
    }

    pub fn assert_ring_irq(self: *Self, q: *const virtio.Q) !void {
        const i = (@intFromPtr(q) - @intFromPtr(&self.vqs)) / @sizeOf(@TypeOf(q.*));
        if (self.vq_properties[i].msix_idx) |msix_idx| {
            const msix_ctrl = mem.readInt(u16, mem.asBytes(self.global_msix_ctrl), .little);
            if (msix_ctrl & pci.c.PCI_MSIX_FLAGS_ENABLE != 0) {
                if (msix_ctrl & pci.c.PCI_MSIX_FLAGS_MASKALL != 0 or self.bar1.queue_msix[msix_idx].ctrl & mem.nativeToLittle(u32, pci.c.PCI_MSIX_ENTRY_CTRL_MASKBIT) != 0) {
                    // set pending in PBA
                    self.bar1.pba[msix_idx] = 1;
                } else {
                    if (self.vq_properties[i].msix == null) {
                        self.vq_properties[i].msix = try MSIX.init(self.get_msix_irq(q).?);
                    }
                    try self.vq_properties[i].msix.?.trigger();
                }
                return;
            }
        }
        self.bar0.irq_status |= 1;
        try self.update_irq(self.irq);
    }

    fn update_irq(self: *const Self, irq: u32) !void {
        if (self.bar0.irq_status != 0) {
            try kvm.setIrqLevel(irq, 1);
        } else {
            try kvm.setIrqLevel(irq, 0);
        }
    }

    fn handler0(ctx: ?*anyopaque, offset: u64, op: io.Operation, data: []u8) !void {
        var self: *Self = @alignCast(@ptrCast(ctx));
        const i = mem.readInt(u16, mem.asBytes(&self.bar0.cfg.queue_select), .little);

        switch (offset) {
            @offsetOf(c.virtio_pci_common_cfg, "device_feature") => switch (op) {
                .Read => if (self.bar0.cfg.device_feature_select == 0) {
                    @memcpy(data, mem.asBytes(&self.device_feature)[0..4]);
                } else {
                    @memcpy(data, mem.asBytes(&self.device_feature)[4..]);
                },
                else => unreachable,
            },
            @offsetOf(c.virtio_pci_common_cfg, "guest_feature") => switch (op) {
                .Write => if (self.bar0.cfg.guest_feature_select == 0) {
                    self.driver_features |= mem.readInt(u32, data[0..4], .little);
                } else {
                    self.driver_features |= @as(u64, mem.readInt(u32, data[0..4], .little)) << 32;
                },
                else => unreachable,
            },
            @offsetOf(c.virtio_pci_common_cfg, "queue_size") => switch (op) {
                .Read => mem.writeInt(u16, data[0..2], 256, .little),
                .Write => self.vq_properties[i].size = mem.readInt(u16, data[0..2], .little),
            },
            @offsetOf(c.virtio_pci_common_cfg, "queue_desc_lo") => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.vq_properties[i].descs &= 0xffffffff_00000000;
                    self.vq_properties[i].descs |= mem.readInt(u32, data[0..4], .little);
                },
            },
            @offsetOf(c.virtio_pci_common_cfg, "queue_desc_hi") => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.vq_properties[i].descs &= 0x00000000_ffffffff;
                    self.vq_properties[i].descs |= (@as(u64, mem.readInt(u32, data[0..4], .little)) << 32);
                },
            },
            @offsetOf(c.virtio_pci_common_cfg, "queue_avail_lo") => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.vq_properties[i].avail &= 0xffffffff_00000000;
                    self.vq_properties[i].avail |= mem.readInt(u32, data[0..4], .little);
                },
            },
            @offsetOf(c.virtio_pci_common_cfg, "queue_avail_hi") => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.vq_properties[i].avail &= 0x00000000_ffffffff;
                    self.vq_properties[i].avail |= (@as(u64, mem.readInt(u32, data[0..4], .little)) << 32);
                },
            },
            @offsetOf(c.virtio_pci_common_cfg, "queue_used_lo") => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.vq_properties[i].used &= 0xffffffff_00000000;
                    self.vq_properties[i].used |= mem.readInt(u32, data[0..4], .little);
                },
            },
            @offsetOf(c.virtio_pci_common_cfg, "queue_used_hi") => switch (op) {
                .Read => unreachable,
                .Write => {
                    self.vq_properties[i].used &= 0x00000000_ffffffff;
                    self.vq_properties[i].used |= (@as(u64, mem.readInt(u32, data[0..4], .little)) << 32);
                },
            },
            @offsetOf(c.virtio_pci_common_cfg, "queue_enable") => switch (op) {
                .Read => if (self.vqs[i] != null) mem.writeInt(u16, data[0..2], 1, .little) else mem.writeInt(u16, data[0..2], 0, .little),
                .Write => {
                    const enable = mem.readInt(u16, data[0..2], .little);
                    if (enable > 0) {
                        const eventfd = try std.posix.eventfd(0, 0);
                        kvm.addIOEventFd(self.pdev.bar_gpa(0) + @offsetOf(BAR0, "notify"), @sizeOf(@TypeOf(self.bar0.notify)), eventfd, i) catch {
                            self.not_support_ioeventfd = true;
                        };
                        const q = try virtio.Q.init(.{ .v2 = .{
                            .descs_addr = self.vq_properties[i].descs,
                            .avail_addr = self.vq_properties[i].avail,
                            .used_addr = self.vq_properties[i].used,
                        } }, self.vq_properties[i].size, 0, self.driver_features, mem.page_size, eventfd);
                        self.vqs[i] = q;
                        try self.init_queue_proc(self, &self.vqs[i].?);
                    } else {
                        self.vqs[i].?.deinit();
                        self.vqs[i] = null;
                        if (self.vq_properties[i].msix) |*msix| {
                            msix.deinit();
                            self.vq_properties[i].msix = null;
                            self.vq_properties[i].msix_idx = null;
                        }
                    }
                },
            },
            @offsetOf(BAR0, "notify") => switch (op) {
                .Read => unreachable,
                .Write => if (self.not_support_ioeventfd) {
                    const qi = mem.readInt(u32, data[0..4], .little);
                    try self.vqs[qi].?.notifyAvail();
                } else unreachable,
            },
            @offsetOf(BAR0, "irq_status") => switch (op) {
                .Write => unreachable,
                .Read => {
                    // read to clear
                    data[0] = @truncate(self.bar0.irq_status);
                    self.bar0.irq_status = 0;
                    try self.update_irq(self.irq);
                },
            },

            @offsetOf(BAR0, "dev_cfg")...@offsetOf(BAR0, "dev_cfg") + @sizeOf(@TypeOf(self.bar0.dev_cfg)) => try self.specific_handler(self, offset - @offsetOf(BAR0, "dev_cfg"), op, data),
            else => switch (op) {
                .Read => @memcpy(data, mem.asBytes(&self.bar0)[offset..][0..data.len]),
                .Write => @memcpy(mem.asBytes(&self.bar0)[offset..][0..data.len], data),
            },
        }

        if (offset == @offsetOf(c.virtio_pci_common_cfg, "queue_msix_vector") and op == .Write) {
            self.vq_properties[i].msix_idx = mem.readInt(u16, data[0..2], .little);
        }

        if (offset == @offsetOf(c.virtio_pci_common_cfg, "msix_config") and op == .Write) {
            std.debug.assert(self.bar0.cfg.msix_config == 0); // config vector should be the first in msix table
        }

        // reset device
        if (offset == @offsetOf(c.virtio_pci_common_cfg, "device_status") and op == .Write and self.bar0.cfg.device_status == 0) {
            // deinit all queues
            for (0..max_queue_num) |qi| {
                if (self.vqs[qi]) |*q| {
                    q.deinit();
                    self.vqs[qi] = null;
                }
            }
        }

        //std.log.info("bar0: {} 0x{x} {any}", .{ op, offset, data });
    }

    fn handler1(ctx: ?*anyopaque, offset: u64, op: io.Operation, data: []u8) !void {
        var self: *Self = @alignCast(@ptrCast(ctx));
        switch (op) {
            .Read => @memcpy(data, mem.asBytes(&self.bar1)[offset..][0..data.len]),
            .Write => @memcpy(mem.asBytes(&self.bar1)[offset..][0..data.len], data),
        }

        //std.log.info("bar1: {} 0x{x} {any}", .{ op, offset, data });
    }
};

const max_devs = 32;
var registered_devs: [max_devs]Dev = undefined;
var registered_num: usize = 0;

pub fn get_registered_devs() []Dev {
    return registered_devs[0..registered_num];
}

fn register_dev(comptime kind: enum { blk, net }, irq: u32, h: *const fn (*Dev, u64, io.Operation, []u8) anyerror!void) !*Dev {
    const redhat_qumranet_vendor = 0x1af4;
    const device_id = switch (kind) {
        .blk => 0x1001, // PCI_DEVICE_ID_VIRTIO_BLK
        .net => 0x1000, // PCI_DEVICE_ID_VIRTIO_NET
    };
    const subsys_id = switch (kind) {
        .blk => virtio.c.VIRTIO_ID_BLOCK,
        .net => virtio.c.VIRTIO_ID_NET,
    };
    const class = switch (kind) {
        .blk => 0x0180, // PCI_CLASS_BLK
        .net => 0x0200, // PCI_CLASS_NET
    };

    if (registered_num == max_devs) return error.TOO_MANY;

    const vpdev = &registered_devs[registered_num];
    try vpdev.init(irq, redhat_qumranet_vendor, device_id, redhat_qumranet_vendor, subsys_id, class, h);

    registered_num += 1;

    return vpdev;
}

pub fn register_blk_dev(irq: u32, h: *const fn (*Dev, u64, io.Operation, []u8) anyerror!void) !*Dev {
    return register_dev(.blk, irq, h);
}

pub fn register_net_dev(irq: u32, h: *const fn (*Dev, u64, io.Operation, []u8) anyerror!void) !*Dev {
    return register_dev(.net, irq, h);
}
