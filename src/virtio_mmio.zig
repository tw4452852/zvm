const std = @import("std");
const io = @import("io.zig");
const mmio = @import("mmio.zig");
const fmt = std.fmt;

const IO_SIZE = 0x200;

pub const Dev = struct {
    name: []const u8,
    irq: u32,
    start: u64,
    len: u64,
    next: ?*Dev,
};

var registered_devs: ?*Dev = null;
var registered_num: usize = 0;

pub fn get_registered_devs() ?*Dev {
    return registered_devs;
}

pub fn register_dev(allocator: std.mem.Allocator, irq: u8, h: *const fn (u64, io.Operation, u32, []u8) anyerror!void) !u64 {
    const addr = mmio.alloc_space(IO_SIZE);

    try mmio.register_handler(addr, IO_SIZE, h);

    const dev: Dev = .{
        .name = try fmt.allocPrint(allocator, "virtio_mmio{}", .{registered_num}),
        .irq = irq,
        .start = addr,
        .len = IO_SIZE,
        .next = registered_devs,
    };
    const pdev = try allocator.create(Dev);
    pdev.* = dev;
    registered_devs = pdev;
    registered_num += 1;

    return addr;
}
