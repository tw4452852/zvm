const std = @import("std");
const os = std.os;
const mem = std.mem;
const root = @import("root");
const Arch = root.Arch;
const kvm = root.kvm;
const native_endian = @import("builtin").cpu.arch.endian();

var next: u32 = Arch.start_irq;

pub fn alloc() u32 {
    defer next += 1;
    return next;
}

pub fn gsi(irq: u32) u32 {
    return irq - Arch.start_irq;
}

pub const MSIX = struct {
    const Self = @This();
    irq: u32,
    eventfd: os.fd_t,

    pub fn init(irq: u32) !Self {
        const fd = try os.eventfd(0, 0);
        try kvm.addIrqFd(gsi(irq), fd, null);

        return .{
            .irq = irq,
            .eventfd = fd,
        };
    }

    pub fn deinit(self: *Self) void {
        os.close(self.eventfd);
    }

    pub fn trigger(self: *Self) !void {
        const f: std.fs.File = .{
            .handle = self.eventfd,
        };

        const w = f.writer();
        try w.writeInt(u64, 1, native_endian);
    }
};
