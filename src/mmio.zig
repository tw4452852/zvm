const std = @import("std");
const io = @import("io.zig");

pub const GAP_SIZE = (768 << 20);
pub const GAP_START = (1 << 32) - GAP_SIZE;

const min_alignment = (1 << 12); // one page
var free_start: u64 = GAP_START;
pub fn alloc_space(size: u64) u64 {
    const ret = std.mem.alignForward(u64, free_start, min_alignment);

    free_start = ret + size;
    if (free_start >= GAP_START + GAP_SIZE) @panic("no enough MMIO space");

    return ret;
}

const limit = 32;
var handler_array: [limit]H = undefined;
var handlers: usize = 0;

pub const Handler = *const fn (?*anyopaque, u64, io.Operation, []u8) anyerror!void;
const H = struct {
    start: u64,
    end: u64,
    handle: Handler,
    ctx: ?*anyopaque,
};

pub fn register_handler(start: u64, count: u64, h: Handler, ctx: ?*anyopaque) !void {
    if (handlers == limit) return error.NO_SPACE;
    handler_array[handlers] = .{
        .start = start,
        .end = start + count,
        .handle = h,
        .ctx = ctx,
    };
    handlers += 1;
}

pub fn deregister_handler(start: u64, count: u64, handler: Handler, ctx: ?*anyopaque) !void {
    for (handler_array[0..handlers]) |*h| {
        if (h.start == start and h.end == start + count and h.handle == handler and h.ctx == ctx) {
            h.* = handler_array[handlers - 1];
            handlers -= 1;
            break;
        }
    } else return error.NOT_FOUND;
}

pub fn dump() void {
    for (handler_array[0..handlers], 0..) |h, i| {
        std.debug.print("{}: 0x{x} - 0x{x}\n", .{ i, h.start, h.end });
    }
}

pub fn handle(addr: u64, op: io.Operation, data: []u8) !void {
    for (handler_array[0..handlers]) |h| {
        if (h.start <= addr and addr < h.end) return h.handle(h.ctx, addr - h.start, op, data);
    } else {
        std.log.err("unhandled {} {any}@0x{x}", .{ op, data, addr });
        unreachable;
    }
}
