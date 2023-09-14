const std = @import("std");
const Thread = std.Thread;
const fmt = std.fmt;
const os = std.os;
const kvm = @import("root").kvm;
const c = @import("root").c;
const ioctl = os.linux.ioctl;
const log = std.log;
const portio = @import("portio.zig");
const mmio = @import("mmio.zig");
const io = @import("io.zig");
const Arch = @import("arch/index.zig").Arch;
const assert = std.debug.assert;
const root = @import("root");
const mem = std.mem;

pub fn createAndStartCpus(num_cores: usize) !void {
    var buf: [16]u8 = undefined;
    var cpus: [root.MAX_CPUS]os.fd_t = undefined;
    var handle0: Thread = undefined;
    assert(num_cores < root.MAX_CPUS);

    for (cpus[0..num_cores], 0..) |*cpu, i| {
        // create vcpu
        const vcpu = try kvm.createVCPU(i);

        // enable debug if any
        if (root.enable_debug) {
            const debug = mem.zeroInit(c.kvm_guest_debug, .{ .control = c.KVM_GUESTDBG_ENABLE | c.KVM_GUESTDBG_SINGLESTEP });
            const ret = ioctl(vcpu, c.KVM_SET_GUEST_DEBUG, @intFromPtr(&debug));
            if (os.linux.getErrno(ret) != .SUCCESS) {
                log.err("failed to enable debug: {}", .{os.linux.getErrno(ret)});
                return error.CREATE_CPU;
            }
            log.info("enable debug", .{});
        }

        try Arch.init_vcpu(vcpu, i);

        cpu.* = vcpu;
    }

    for (cpus[0..num_cores], 0..) |cpu, i| {
        const h = try Thread.spawn(.{}, runVCPU, .{cpu});
        try h.setName(try fmt.bufPrint(buf[0..], "vcpu-{}", .{i}));
        if (i == 0) handle0 = h;
    }
    handle0.join();
}

fn runVCPU(vcpu: os.fd_t) !void {
    const run_ptr = try kvm.getRun(vcpu);
    const run: *c.kvm_run = @ptrCast(run_ptr.ptr);

    while (true) {
        const ret = ioctl(vcpu, c.KVM_RUN, 0);
        const errno = os.linux.getErrno(ret);
        if (errno != .SUCCESS) {
            log.err("failed to run vcpu: {}", .{errno});
            if (errno == .INTR or errno == .AGAIN) continue;
            return error.RUN;
        }

        const ctx = &run.unnamed_0;
        const reason: kvm.ExitReason = @enumFromInt(run.exit_reason);
        switch (reason) {
            .io => {
                //log.info("io: 0x{X}, direction[{}], count[{}], size[{}]", .{ ctx.io.port, ctx.io.direction, ctx.io.count, ctx.io.size });
                try portio.handle(ctx.io.port, @enumFromInt(ctx.io.direction), ctx.io.size, ctx.io.count, run_ptr[ctx.io.data_offset .. ctx.io.data_offset + ctx.io.count * ctx.io.size]);
            },
            .mmio => {
                //log.info("mmio: 0x{X}, is_write[{}], len[{}], data[{any}]", .{ ctx.mmio.phys_addr, ctx.mmio.is_write, ctx.mmio.len, ctx.mmio.data[0..ctx.mmio.len] });
                try mmio.handle(ctx.mmio.phys_addr, @enumFromInt(ctx.mmio.is_write), ctx.mmio.len, &ctx.mmio.data);
            },
            .shutdown => {
                log.info("shutdown", .{});
                try Arch.dump_vcpu(vcpu);
                return;
            },
            .debug => {
                try Arch.record_ins(vcpu, &ctx.debug.arch);
            },
            else => {
                log.info("not supported reason: {}", .{reason});
                try Arch.record_ins(vcpu, null);
                try Arch.dump_vcpu(vcpu);
                return error.RUN;
            },
        }
    }
}
