const std = @import("std");
const fs = std.fs;
const log = std.log;
const os = std.os;
const ioctl = os.linux.ioctl;
const c = @import("root").c;
const assert = std.debug.assert;
const mmio = @import("mmio.zig");
const Arch = @import("arch/index.zig").Arch;
const hasFn = std.meta.trait.hasFn;

var f: fs.File = undefined;
var vm: os.fd_t = undefined;
var mem: []u8 = undefined;

pub const ExitReason = enum {
    unknown, // 0
    exception, // 1
    io, // 2
    hypercall, // 3
    debug, // 4
    hlt, // 5
    mmio, // 6
    irq_window_open, // 7
    shutdown, // 8
    fail_entry, // 9
    intr, // 10
    set_tpr, // 11
    tpr_access, // 12
    s390_sieic, // 13
    s390_reset, // 14
    dcr, // 15
    nmi, // 16
    internal_err, // 17
    osi, // 18
    papr_hcall, // 19
    s390_ucontrol, // 20
    watchdog, // 21
    s390_tsch, // 22
    epr, // 23
    system_event, // 24
    s390_stsi, // 25
    ioapic_eoi, // 26
    hyperv, // 27
    arm_nisv, // 28
    x86_rdmsr, // 29
    x86_wrmsr, // 30
};

pub fn open() !void {
    f = try fs.cwd().openFile("/dev/kvm", .{
        .mode = .read_write,
    });

    const version = ioctl(f.handle, c.KVM_GET_API_VERSION, 0);
    log.info("kvm version = {}", .{version});
}

pub fn close() void {
    f.close();
}

pub fn getVM() os.fd_t {
    return vm;
}

pub fn getMem() []u8 {
    return mem;
}

pub fn createVM(ram_size: usize) !void {
    var ret = ioctl(f.handle, c.KVM_CREATE_VM, 0);
    if (os.linux.getErrno(ret) != .SUCCESS) {
        log.err("failed to create vm: {}", .{os.linux.getErrno(ret)});
        return error.CREATE_VM;
    }
    vm = @intCast(ret);

    const real_size = if (ram_size < mmio.GAP_START) ram_size else ram_size + mmio.GAP_SIZE;
    mem = try os.mmap(null, real_size, c.PROT_READ | c.PROT_WRITE, c.MAP_PRIVATE | c.MAP_ANONYMOUS | c.MAP_NORESERVE, -1, 0);
    var region: c.kvm_userspace_memory_region = .{
        .slot = 0,
        .guest_phys_addr = 0,
        .memory_size = real_size,
        .userspace_addr = @intFromPtr(mem.ptr),
        .flags = 0,
    };
    ret = ioctl(vm, c.KVM_SET_USER_MEMORY_REGION, @intFromPtr(&region));
    if (os.linux.getErrno(ret) != .SUCCESS) {
        log.err("failed to initialize memory: {}", .{os.linux.getErrno(ret)});
        return error.CREATE_MEM;
    }
}

pub fn destroyVM() void {
    os.close(vm);
    vm = undefined;
}

pub fn createVCPU(i: usize) !os.fd_t {
    const ret = ioctl(vm, c.KVM_CREATE_VCPU, i);
    if (os.linux.getErrno(ret) != .SUCCESS) {
        log.err("failed to create cpu{}: {}", .{ i, os.linux.getErrno(ret) });
        return error.CREATE_CPU;
    }
    return @intCast(ret);
}

pub fn fixCpuids(vcpu: os.fd_t, i: usize, cb: *const fn (usize, *c.kvm_cpuid_entry2) void) !void {
    const _CPUID = extern struct {
        nent: u32,
        padding: u32,
        entries: [100]c.kvm_cpuid_entry2,
    };
    var cpuid = std.mem.zeroInit(_CPUID, .{ .nent = 100 });
    var ret = ioctl(f.handle, c.KVM_GET_SUPPORTED_CPUID, @intFromPtr(&cpuid));
    if (os.linux.getErrno(ret) != .SUCCESS) {
        log.err("failed to get supported cpuid: {}", .{os.linux.getErrno(ret)});
        return error.CPUID;
    }

    for (&cpuid.entries) |*entry| {
        cb(i, entry);
    }

    ret = ioctl(vcpu, c.KVM_SET_CPUID2, @intFromPtr(&cpuid));
    if (os.linux.getErrno(ret) != .SUCCESS) {
        log.err("failed to set cpuid: {}", .{os.linux.getErrno(ret)});
        return error.CPUID;
    }
}

pub fn getRun(vcpu: os.fd_t) ![]align(4096) u8 {
    const ret = ioctl(f.handle, c.KVM_GET_VCPU_MMAP_SIZE, 0);
    if (os.linux.getErrno(ret) != .SUCCESS) {
        log.err("failed to get run size: {}", .{os.linux.getErrno(ret)});
        return error.RUN;
    }
    return try os.mmap(null, ret, c.PROT_READ | c.PROT_WRITE, c.MAP_SHARED, vcpu, 0);
}

var irq_mutex = std.Thread.Mutex{};

const setIrqLevelInner = if (hasFn("setIrqLevelInner")(Arch)) Arch.setIrqLevelInner else blk: {
    const S = struct {
        pub fn setIrqLevelInner(irq: u32, level: u1) !void {
            const irq_level: c.kvm_irq_level = .{ .unnamed_0 = .{
                .irq = irq,
            }, .level = level };

            const ret = ioctl(vm, c.KVM_IRQ_LINE, @intFromPtr(&irq_level));
            //log.info("tw; set irq{}, level = {}", .{ irq_level.unnamed_0.irq, irq_level.level });
            if (os.linux.getErrno(ret) != .SUCCESS) {
                log.err("failed to set irq{}, level{}: {}", .{ irq, level, os.linux.getErrno(ret) });
                return error.IRQ;
            }
        }
    };

    break :blk S.setIrqLevelInner;
};

pub fn setIrqLevel(irq: u32, level: u1) !void {
    irq_mutex.lock();
    defer irq_mutex.unlock();
    try setIrqLevelInner(irq, level);
}

pub fn triggerIrq(irq: u32) !void {
    irq_mutex.lock();
    defer irq_mutex.unlock();

    try setIrqLevelInner(irq, 1);
    try setIrqLevelInner(irq, 0);
}

pub fn addIOEventFd(addr: u64, len: u32, fd: os.fd_t, datamatch: ?u64) !void {
    var ret = ioctl(f.handle, c.KVM_CHECK_EXTENSION, c.KVM_CAP_IOEVENTFD);
    if (os.linux.getErrno(ret) != .SUCCESS) {
        log.err("don't support ioeventfd", .{});
        return error.NOT_SUPPORT;
    }

    //log.info("tw; 0x{x}, {} {}\n", .{ addr, len, fd });
    var ioevent = std.mem.zeroes(c.kvm_ioeventfd);
    ioevent.addr = addr;
    ioevent.len = len;
    ioevent.datamatch = if (datamatch) |match| match else 0;
    ioevent.fd = fd;
    ioevent.flags = if (datamatch != null) c.KVM_IOEVENTFD_FLAG_DATAMATCH else 0;

    ret = ioctl(vm, c.KVM_IOEVENTFD, @intFromPtr(&ioevent));
    if (os.linux.getErrno(ret) != .SUCCESS) {
        log.err("failed to add ioeventfd: {}", .{os.linux.getErrno(ret)});
        return error.IOEVENTFD;
    }
}
