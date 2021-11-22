const std = @import("std");
const Thread = std.Thread;
const serial = @import("hw/8250.zig");
const fs = std.fs;
const os = std.os;

var tty: fs.File = undefined;
var original_termios: os.termios = undefined;
var handle: std.Thread = undefined;
var stop = false;

pub fn startCapture() !void {
    tty = try fs.cwd().openFile("/dev/tty", .{ .read = true, .write = true });
    original_termios = try os.tcgetattr(tty.handle);

    var raw = original_termios;
    raw.lflag &= ~@as(
        os.system.tcflag_t,
        os.system.ECHO | os.system.ICANON,
    );
    raw.cc[os.system.V.TIME] = 1;
    raw.cc[os.system.V.MIN] = 1;
    try os.tcsetattr(tty.handle, .FLUSH, raw);

    handle = try Thread.spawn(.{}, captureStdin, .{tty});
}

pub fn stopCapture() void {
    stop = true;
    os.tcsetattr(tty.handle, .FLUSH, original_termios) catch unreachable;
    handle.join();
    tty.close();
}

fn captureStdin(f: fs.File) !void {
    var buf: [64]u8 = undefined;

    while (!stop) {
        const n = try f.read(buf[0..64]);
        if (n > 0) {
            try serial.forwardStdin(buf[0..n]);
        }
    }
}
