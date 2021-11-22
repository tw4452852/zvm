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
const arch = @import("arch/index.zig");
const assert = std.debug.assert;
const root = @import("root");
const mem = std.mem;

pub fn createAndStartCpus(num_cores: usize) !void {
    var buf: [16]u8 = undefined;
    var cpus: [root.MAX_CPUS]os.fd_t = undefined;
    var handle0: Thread = undefined;
    assert(num_cores < root.MAX_CPUS);

    for (cpus[0..num_cores]) |*cpu, i| {
        // create vcpu
        const vcpu = try kvm.createVCPU(i);

        // enable debug if any
        if (root.enable_debug) {
            const debug = mem.zeroInit(c.kvm_guest_debug, .{ .control = c.KVM_GUESTDBG_ENABLE | c.KVM_GUESTDBG_SINGLESTEP });
            const ret = ioctl(vcpu, c.KVM_SET_GUEST_DEBUG, @ptrToInt(&debug));
            if (os.errno(ret) != .SUCCESS) {
                log.err("failed to enable debug: {}", .{os.errno(ret)});
                return error.CREATE_CPU;
            }
            log.info("enable debug", .{});
        }

        try arch.init_vcpu(vcpu, i);

        cpu.* = vcpu;
    }

    for (cpus[0..num_cores]) |cpu, i| {
        const h = try Thread.spawn(.{}, runVCPU, .{cpu});
        try h.setName(try fmt.bufPrint(buf[0..], "vcpu-{}", .{i}));
        if (i == 0) handle0 = h;
    }
    handle0.join();
}

fn runVCPU(vcpu: os.fd_t) !void {
    const run_ptr = try kvm.getRun(vcpu);
    const run = @ptrCast(*volatile c.kvm_run, run_ptr.ptr);

    while (true) {
        const ret = ioctl(vcpu, c.KVM_RUN, 0);
        const errno = os.errno(ret);
        if (errno != .SUCCESS) {
            log.err("failed to run vcpu: {}", .{errno});
            if (errno == .INTR or errno == .AGAIN) continue;
            return error.RUN;
        }

        const ctx = &run.unnamed_0;
        const reason = @intToEnum(kvm.ExitReason, run.exit_reason);
        switch (reason) {
            .io => {
                //log.info("io: 0x{X}, {}, [{}]{}", .{ ctx.io.port, ctx.io.direction, ctx.io.count, ctx.io.size });
                try portio.handle(ctx.io.port, @intToEnum(io.Operation, ctx.io.direction), ctx.io.size, ctx.io.count, run_ptr[ctx.io.data_offset .. ctx.io.data_offset + ctx.io.count * ctx.io.size]);
            },
            .mmio => {
                //log.info("io: 0x{X}, {}, [{}]{}", .{ ctx.io.port, ctx.io.direction, ctx.io.count, ctx.io.size });
                try mmio.handle(ctx.mmio.phys_addr, @intToEnum(io.Operation, ctx.mmio.is_write), ctx.mmio.len, &ctx.mmio.data);
            },
            .shutdown => {
                log.info("shutdown", .{});
                try arch.dump_vcpu(vcpu);
                return;
            },
            .debug => {
                try arch.record_ins(vcpu, ctx.debug.arch.pc);
            },
            .unknown => continue,
            else => {
                log.info("not supported reason: {}", .{reason});
                try arch.record_ins(vcpu, null);
                try arch.dump_vcpu(vcpu);
                return error.RUN;
            },
        }
    }
}
