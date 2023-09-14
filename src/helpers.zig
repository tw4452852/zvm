const std = @import("std");
const print = std.debug.print;

pub fn check_non_zero(ret: anytype) !void {
    if (ret != 0) {
        switch (@TypeOf(ret)) {
            usize => print("ret: {} {}\n", .{ @as(isize, @bitCast(ret)), std.os.linux.getErrno(ret) }),
            else => print("ret: {}\n", .{ret}),
        }
        return error.RET_NON_ZERO;
    }
}
