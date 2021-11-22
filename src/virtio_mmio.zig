const std = @import("std");
const io = @import("io.zig");
const mmio = @import("mmio.zig");
const fmt = std.fmt;

const IO_SIZE = 0x200;

pub fn register_dev(allocator: std.mem.Allocator, irq: u8, cmdline: *[]const u8, h: fn (u64, io.Operation, u32, []u8) anyerror!void) !u64 {
    const addr = mmio.alloc_space(IO_SIZE);

    cmdline.* = try fmt.allocPrint(allocator, "{s} virtio_mmio.device=0x{x}@0x{x}:{}", .{ cmdline.*, IO_SIZE, addr, irq });
    try mmio.register_handler(addr, IO_SIZE, h);

    return addr;
}
