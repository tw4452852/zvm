const std = @import("std");
const root = @import("root");
const mmio = @import("mmio.zig");
const io = @import("io.zig");

pub const cfg_size = 1 << 28;
pub var cfg_start: ?u64 = null;

pub fn init() !void {
	cfg_start = mmio.alloc_space(cfg_size);
	try mmio.register_handler(cfg_start.?, cfg_size, handle, null);
}

pub fn deinit() void {}

fn handle(_: ?*anyopaque, offset: u64, op: io.Operation, len: u32, data: []u8) !void {
	std.log.info("{} 0x{x} {any}", .{op, offset, data[0..len]});

}