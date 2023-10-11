const std = @import("std");
const pci = @import("pci.zig");
const io = @import("io.zig");
const virtio = @import("virtio.zig");
const kvm = @import("root").kvm;
const mem = std.mem;
const mmio = @import("mmio.zig");
pub const c = @cImport({
    @cInclude("linux/virtio_pci.h");
});

const BAR0 = struct {
    cfg: c.virtio_pci_common_cfg,
    irq_status: u8,
    notify: c.virtio_pci_notify_cap,
};

pub const Dev = struct {
    const Self = @This();
    const Handler = *const fn (*Self, u64, io.Operation, u32, []u8) anyerror!void;

    allocator: mem.Allocator,
    irq: u32,
    specific_handler: Handler,
    pdev: *pci.Dev,
    next: ?*Dev = null,
    init_queue_proc: *const fn (dev: *Self, q: *virtio.Q) anyerror!void = undefined,
    bar0: BAR0,

    pub fn init(allocator: mem.Allocator, irq: u32, vendor_id: u16, device_id: u16, subsys_vendor_id: u16, subsys_id: u16, class: u24, specific_handler: Handler) !*Self {
        const p = try allocator.create(Self);
        const pdev = try pci.register(vendor_id, device_id, subsys_vendor_id, subsys_id, class);

        // prepare bar0
        try pdev.allocate_bar(0, mem.alignForward(u64, @sizeOf(BAR0), 4096));

        // register common cfg capability for modern virtio pci device
        const comm_cfg: c.virtio_pci_cap = .{
            .cap_vndr = pci.c.PCI_CAP_ID_VNDR,
            .cap_next = 0,
            .cap_len = @sizeOf(c.virtio_pci_cap),
            .cfg_type = c.VIRTIO_PCI_CAP_COMMON_CFG,
            .bar = 0,
            .id = 0,
            .padding = .{ 0, 0 },
            .offset = mem.readIntLittle(u32, mem.asBytes(&@as(u32, @offsetOf(BAR0, "cfg")))),
            .length = mem.readIntLittle(u32, mem.asBytes(&@as(u32, @sizeOf(c.virtio_pci_common_cfg)))),
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
            .offset = mem.readIntLittle(u32, mem.asBytes(&@as(u32, @offsetOf(BAR0, "irq_status")))),
            .length = mem.readIntLittle(u32, mem.asBytes(&@as(u32, @sizeOf(u8)))),
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
            .offset = mem.readIntLittle(u32, mem.asBytes(&@as(u32, @offsetOf(BAR0, "notify")))),
            .length = mem.readIntLittle(u32, mem.asBytes(&@as(u32, @sizeOf(c.virtio_pci_notify_cap)))),
        };
        const notify_cap = try pdev.add_cap(@TypeOf(notify_cfg));
        notify_cap.* = notify_cfg;

        const dev: Self = .{
            .allocator = allocator,
            .irq = irq,
            .pdev = pdev,
            .specific_handler = specific_handler,
            .bar0 = mem.zeroes(BAR0),
        };

        p.* = dev;

        return p;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self);
    }

    pub fn set_device_features(self: *Self, features: u64) void {
        self.bar0.cfg.device_feature = @truncate(features);
    }

    pub fn set_queue_init_proc(self: *Self, init_fn: *const fn (dev: *Self, q: *virtio.Q) anyerror!void) void {
        self.init_queue_proc = init_fn;
    }

    pub fn assert_ring_irq(self: *Self) !void {
        self.bar0.irq_status |= 1;
        try self.update_irq();
    }

    fn update_irq(self: *const Self) !void {
        if (self.bar0.irq_status != 0) {
            try kvm.setIrqLevel(self.irq, 1);
        } else {
            try kvm.setIrqLevel(self.irq, 0);
        }
    }
};

var registered_devs: ?*Dev = null;
var registered_num: usize = 0;

pub fn get_registered_devs() ?*Dev {
    return registered_devs;
}

fn register_dev(comptime kind: enum { blk, net }, allocator: mem.Allocator, irq: u8, h: *const fn (*Dev, u64, io.Operation, u32, []u8) anyerror!void) !*Dev {
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
        .blk => 0x018000, // PCI_CLASS_BLK
        .net => 0x020000, // PCI_CLASS_NET
    };

    const vpdev = try Dev.init(allocator, irq, redhat_qumranet_vendor, device_id, redhat_qumranet_vendor, subsys_id, class, h);

    vpdev.next = registered_devs;
    registered_devs = vpdev;
    registered_num += 1;

    return vpdev;
}

pub fn register_blk_dev(allocator: mem.Allocator, irq: u8, h: *const fn (*Dev, u64, io.Operation, u32, []u8) anyerror!void) !*Dev {
    return register_dev(.blk, allocator, irq, h);
}
