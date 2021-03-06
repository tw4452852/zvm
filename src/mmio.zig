const std = @import("std");
const io = @import("io.zig");

pub const GAP_SIZE = (768 << 20);
pub const GAP_START = (1 << 32) - GAP_SIZE;

var free_start: u64 = GAP_START;
pub fn alloc_space(size: u64) u64 {
    defer free_start += size;
    return free_start;
}

const limit = 32;
var handler_array: [limit]H = undefined;
var handlers: usize = 0;

const H = struct {
    start: u64,
    end: u64,
    handle: fn (u64, io.Operation, u32, []u8) anyerror!void,
};

pub fn register_handler(start: u64, count: u64, h: fn (u64, io.Operation, u32, []u8) anyerror!void) !void {
    if (handlers == limit) return error.NO_SPACE;
    handler_array[handlers] = .{
        .start = start,
        .end = start + count,
        .handle = h,
    };
    handlers += 1;
}

pub fn handle(addr: u64, op: io.Operation, len: u32, data: []u8) !void {
    for (handler_array[0..handlers]) |h| {
        if (h.start <= addr and addr <= h.end) return h.handle(addr - h.start, op, len, data);
    }
}
