const std = @import("std");
const io = @import("io.zig");
const v8250 = @import("hw/8250.zig");
const log = std.log;

const limit = 32;
var handler_array = blk: {
    var a: [limit]H = undefined;
    a[0] = .{
        .start = 0x3f8,
        .end = 0x3f8 + 8,
        .handle = v8250.handle,
    };
    break :blk a;
};
var handlers: usize = 1;

const H = struct {
    start: u16,
    end: u16,
    handle: *const fn (u16, io.Operation, []u8) anyerror!void,
};

pub fn register_handler(start: u16, count: u16, h: *const fn (u16, io.Operation, []u8) anyerror!void) !void {
    if (handlers == limit) return error.NO_SPACE;
    handler_array[handlers] = .{
        .start = start,
        .end = start + count,
        .handle = h,
    };
    handlers += 1;
}

pub fn handle(port: u16, op: io.Operation, val: []u8) !void {
    for (handler_array[0..handlers]) |h| {
        if (h.start <= port and port <= h.end) return h.handle(port - h.start, op, val);
    }
}
