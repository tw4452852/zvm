const std = @import("std");
const os = std.os;
const fs = std.fs;
const ioctl = os.linux.ioctl;
const log = std.log;
const mem = std.mem;
const dprint = std.debug.print;
const root = @import("root");
const c = root.c;
const bootparam = @import("bootparam.zig");
const kvm = @import("root").kvm;
const mpspec = @import("mpspec_def.zig");
const mmio = root.mmio;
const virtio_mmio = root.virtio_mmio;

pub const start_irq = 5;

pub fn init_vm(num_cores: usize) !void {
    const vm = kvm.getVM();

    const pit_config = mem.zeroes(c.kvm_pit_config);
    var ret = ioctl(vm, c.KVM_CREATE_PIT2, @intFromPtr(&pit_config));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to create pit: {}", .{os.errno(ret)});
        return error.CREAT_PIT;
    }

    ret = ioctl(vm, c.KVM_CREATE_IRQCHIP, 0);
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to create irqchip: {}", .{os.errno(ret)});
        return error.CREAT_IRQCHIP;
    }

    initMPTable(num_cores);
}

fn initMPTable(num_cores: usize) void {
    var ram = kvm.getMem();
    const mptable_start = 0x9fc00;

    var p = ram.ptr + mptable_start;
    var mpf_intel: *mpspec.mpf_intel = @alignCast(@ptrCast(p));
    mpf_intel.signature = "_MP_".*;
    mpf_intel.specification = 4;
    mpf_intel.length = 1;
    mpf_intel.physptr = mptable_start + @sizeOf(mpspec.mpf_intel);
    mpf_intel.checksum = blk: {
        var sum: usize = 0;
        var i: usize = 0;
        const start: [*]u8 = @ptrCast(mpf_intel);
        while (i < @sizeOf(mpspec.mpf_intel)) : (i += 1) {
            sum += start[i];
        }
        break :blk 0 -% @as(u8, @truncate(sum));
    };
    p += @sizeOf(mpspec.mpf_intel);

    var mpc_table: *mpspec.mpc_table = @alignCast(@ptrCast(p));
    mpc_table.signature = "PCMP".*;
    mpc_table.spec = 4;
    mpc_table.productid = "123456789abc".*;
    mpc_table.lapic = 0xfee0_0000;
    mpc_table.oem = "12345678".*;
    p += @sizeOf(mpspec.mpc_table);

    var mpc_cpus: [*]mpspec.mpc_cpu = @alignCast(@ptrCast(p));
    var i: u8 = 0;
    while (i < num_cores) : (i += 1) {
        mpc_cpus[i].type = mpspec.MP_PROCESSOR;
        mpc_cpus[i].apicid = i;
        mpc_cpus[i].apicver = 0x14; // xAPIC
        mpc_cpus[i].cpuflag = @as(u8, mpspec.CPU_ENABLED) | if (i == 0) @as(u8, mpspec.CPU_BOOTPROCESSOR) else 0;
        mpc_cpus[i].cpufeature = 0x600; // cpu stepping
        mpc_cpus[i].featureflag = 0x201; // apic and fpu
        p += @sizeOf(mpspec.mpc_cpu);
    }

    var mpc_ioapic: *mpspec.mpc_ioapic = @alignCast(@ptrCast(p));
    const ioapicid = @as(u8, @truncate(num_cores + 1));
    mpc_ioapic.type = mpspec.MP_IOAPIC;
    mpc_ioapic.apicid = ioapicid;
    mpc_ioapic.apicver = 0x14; // xAPIC
    mpc_ioapic.flags = mpspec.MPC_APIC_USABLE;
    mpc_ioapic.apicaddr = 0xfec0_0000;
    p += @sizeOf(mpspec.mpc_ioapic);

    i = 0;
    while (i < 16) : (i += 1) {
        var mpc_intsrc: *mpspec.mpc_intsrc = @alignCast(@ptrCast(p));
        mpc_intsrc.type = mpspec.MP_INTSRC;
        mpc_intsrc.irqtype = mpspec.mp_INT;
        mpc_intsrc.irqflag = mpspec.MP_IRQDIR_DEFAULT;
        mpc_intsrc.srcbus = 0;
        mpc_intsrc.srcbusirq = i;
        mpc_intsrc.dstapic = ioapicid;
        mpc_intsrc.dstirq = i;
        p += @sizeOf(mpspec.mpc_intsrc);
    }

    var mpc_intsrc: *mpspec.mpc_intsrc = @alignCast(@ptrCast(p));
    mpc_intsrc.type = mpspec.MP_LINTSRC;
    mpc_intsrc.irqtype = mpspec.mp_ExtINT;
    mpc_intsrc.irqflag = mpspec.MP_IRQDIR_DEFAULT;
    mpc_intsrc.srcbus = 0;
    mpc_intsrc.srcbusirq = 0;
    mpc_intsrc.dstapic = 0;
    mpc_intsrc.dstirq = 0;
    p += @sizeOf(mpspec.mpc_intsrc);

    mpc_intsrc = @alignCast(@ptrCast(p));
    mpc_intsrc.type = mpspec.MP_LINTSRC;
    mpc_intsrc.irqtype = mpspec.mp_NMI;
    mpc_intsrc.irqflag = mpspec.MP_IRQDIR_DEFAULT;
    mpc_intsrc.srcbus = 0;
    mpc_intsrc.srcbusirq = 0;
    mpc_intsrc.dstapic = 0;
    mpc_intsrc.dstirq = 1;
    p += @sizeOf(mpspec.mpc_intsrc);

    mpc_table.length = @as(u16, @truncate(@intFromPtr(p) - @intFromPtr(mpc_table)));
    mpc_table.checksum = blk: {
        var sum: usize = 0;
        const bytes = @as([*]u8, @ptrCast(mpc_table))[0..mpc_table.length];
        for (bytes) |byte| {
            sum += byte;
        }
        break :blk 0 -% @as(u8, @truncate(sum));
    };
}

pub fn load_kernel(kernel_path: []const u8, cmd: *root.Cmdline, initrd_path: ?[]const u8) !void {
    var ram = kvm.getMem();
    const f = try fs.cwd().openFile(kernel_path, .{});
    defer f.close();

    const fsize = (try f.stat()).size;
    const data = try os.mmap(null, fsize, c.PROT_READ, c.MAP_PRIVATE, f.handle, 0);

    // get the header first
    var hdr: *bootparam.setup_header = @ptrCast(data.ptr + 0x1f1);

    // check the magic number
    if (!mem.eql(u8, @as([*]const u8, @ptrCast(&hdr.header))[0..4], "HdrS")) {
        log.err("invalid magic number: {X}", .{hdr.header});
        return error.BADIMAGE;
    }

    // minimal boot protocol version requirement is 2.06
    if (hdr.version < 0x206) {
        log.err("the boot protocoal version is too low: {X}", .{hdr.version});
        return error.BADIMAGE;
    }

    // copy setup parts to 0x10000 (64K)
    const setup_addr = 0x10_000;
    const setup_size = @as(u32, ((if (hdr.setup_sects == 0) 4 else hdr.setup_sects) + 1)) * 512;
    @memcpy(ram[setup_addr .. setup_addr + setup_size], data[0..setup_size]);

    // copy the reset(vmlinux.bin) to 0x100000 (1M)
    const kernel_addr = 0x100_000;
    const kernel_size = fsize - setup_size;
    if (kernel_addr + kernel_size >= ram.len) {
        log.err("not enough memory for kernel", .{});
        return error.KERNEL;
    }
    @memcpy(ram[kernel_addr .. kernel_addr + kernel_size], data[setup_size .. setup_size + kernel_size]);

    try append_virtio_mmio_cmdline(cmd);
    const cmdline = cmd.constSlice();
    // copy cmdline to 0x20000 (128K)
    const cmd_addr = 0x20_000;
    @memset(ram[cmd_addr .. cmd_addr + hdr.cmdline_size], 0);
    @memcpy(ram[cmd_addr .. cmd_addr + cmdline.len], cmdline[0..cmdline.len]);

    // fill in some necessary fields in setup header
    hdr = @as(*bootparam.setup_header, @ptrCast(ram.ptr + setup_addr + 0x1f1));
    hdr.type_of_loader = 0xff;
    hdr.heap_end_ptr = 0xfe00;
    hdr.loadflags |= @as(u8, bootparam.CAN_USE_HEAP | bootparam.LOADED_HIGH);
    hdr.vid_mode = 0xffff; // normal
    hdr.cmd_line_ptr = cmd_addr;
    prepare_e820(@as([*]bootparam.boot_e820_entry, @ptrCast(ram.ptr + setup_addr + 0x2d0)), @as(*u8, @ptrCast(ram.ptr + setup_addr + 0x1e8)), ram.len);

    hdr.ramdisk_image = 0;
    hdr.ramdisk_size = 0;
    if (initrd_path != null) {
        const initrd_f = try fs.cwd().openFile(initrd_path.?, .{});
        defer initrd_f.close();

        const initrd_size = (try initrd_f.stat()).size;
        const initrd_data = try os.mmap(null, initrd_size, c.PROT_READ, c.MAP_PRIVATE, initrd_f.handle, 0);

        var initrd_addr = @min(hdr.initrd_addr_max, ram.len);
        const kernel_end = kernel_addr + kernel_size;
        while (initrd_addr > kernel_end) : (initrd_addr -= 0x100_000) {
            if (initrd_addr + initrd_size < ram.len) break;
        } else {
            log.err("not enough memory for initrd", .{});
            return error.INITRD;
        }

        log.info("initrd loaded to 0x{X}", .{initrd_addr});
        hdr.ramdisk_image = @as(u32, @truncate(initrd_addr));
        hdr.ramdisk_size = @as(u32, @truncate(initrd_size));
        @memcpy(ram[initrd_addr .. initrd_addr + initrd_size], initrd_data[0..initrd_size]);
    }
}

fn append_virtio_mmio_cmdline(cmd: *root.Cmdline) !void {
    var virtio_mmio_dev: ?*virtio_mmio.Dev = virtio_mmio.get_registered_devs();
    var buf: [64]u8 = undefined;

    while (virtio_mmio_dev) |dev| : (virtio_mmio_dev = dev.next) {
        const s = try std.fmt.bufPrint(&buf, " virtio_mmio.device=0x{x}@0x{x}:{}", .{ dev.len, dev.start, dev.irq });
        try cmd.appendSlice(s);
    }
}

fn prepare_e820(e820_table: [*]bootparam.boot_e820_entry, table_size: *u8, mem_size: usize) void {
    var i: u8 = 0;

    const E820_RAM = 1;
    const E820_RESERVED = 2;
    const bios_start = 0xa0_000;
    const bios_end = 0x100_000;

    e820_table[i] = .{
        .addr = 0,
        .size = bios_start,
        .type = E820_RAM,
    };
    i += 1;

    e820_table[i] = .{
        .addr = bios_start,
        .size = bios_end - bios_start,
        .type = E820_RESERVED,
    };
    i += 1;

    if (mem_size <= mmio.GAP_START) {
        e820_table[i] = .{
            .addr = bios_end,
            .size = mem_size - bios_end,
            .type = E820_RAM,
        };
        i += 1;
    } else {
        e820_table[i] = .{
            .addr = bios_end,
            .size = mmio.GAP_START - bios_end,
            .type = E820_RAM,
        };
        i += 1;
        e820_table[i] = .{
            .addr = mmio.GAP_START + mmio.GAP_SIZE,
            .size = mem_size - (mmio.GAP_START + mmio.GAP_SIZE),
            .type = E820_RAM,
        };
        i += 1;
    }

    table_size.* = i;
}

pub fn init_vcpu(vcpu: os.fd_t, i: usize) !void {
    try setup_lapic(vcpu);
    try setup_cpuid(vcpu, i);
    try setup_regs(vcpu);
}

fn setup_lapic(vcpu: os.fd_t) !void {
    var state: c.kvm_lapic_state = undefined;
    var ret = ioctl(vcpu, c.KVM_GET_LAPIC, @intFromPtr(&state));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to get lapic state: {}", .{os.errno(ret)});
        return error.LAPIC;
    }

    const APIC_LVT0 = 0x350;
    const APIC_LVT1 = 0x360;
    const APIC_MODE_EXTINT = 0x7;
    const APIC_MODE_NMI = 0x4;

    // LVT0 is set for external interrupts
    const lint0: *u32 = @alignCast(@ptrCast(&state.regs[APIC_LVT0]));
    lint0.* |= APIC_MODE_EXTINT << 8;

    // LVT1 is set for NMI
    const lint1: *u32 = @alignCast(@ptrCast(&state.regs[APIC_LVT1]));
    lint1.* |= APIC_MODE_NMI << 8;

    ret = ioctl(vcpu, c.KVM_SET_LAPIC, @intFromPtr(&state));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to set lapic state: {}", .{os.errno(ret)});
        return error.LAPIC;
    }
}

fn setup_cpuid(vcpu: os.fd_t, i: usize) !void {
    const CPUID = struct {
        fn fix(cpuid: usize, entry: *c.kvm_cpuid_entry2) void {
            switch (entry.function) {
                1 => {
                    const initial_apicid_shift = 24;
                    entry.ebx &= ~(@as(c_uint, 0xff) << initial_apicid_shift);
                    entry.ebx |= @as(c_uint, @truncate(cpuid)) << initial_apicid_shift;
                },
                11 => {
                    // EDX bits 31..0 contain x2APIC ID of current logical processor.
                    entry.edx = @as(c_uint, @truncate(cpuid));
                },
                else => {},
            }
        }
    };
    return kvm.fixCpuids(vcpu, i, CPUID.fix);
}

fn setup_regs(vcpu: os.fd_t) !void {
    // setup selector regs
    var sregs: c.kvm_sregs = undefined;
    var ret = ioctl(vcpu, c.KVM_GET_SREGS, @intFromPtr(&sregs));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to get sregs: {}", .{os.errno(ret)});
        return error.REGS;
    }

    sregs.cs.base = 0;
    sregs.cs.limit = std.math.maxInt(u32);
    sregs.cs.g = 1;
    sregs.ds.base = 0;
    sregs.ds.limit = std.math.maxInt(u32);
    sregs.ds.g = 1;
    sregs.fs.base = 0;
    sregs.fs.limit = std.math.maxInt(u32);
    sregs.fs.g = 1;
    sregs.gs.base = 0;
    sregs.gs.limit = std.math.maxInt(u32);
    sregs.gs.g = 1;
    sregs.es.base = 0;
    sregs.es.limit = std.math.maxInt(u32);
    sregs.es.g = 1;
    sregs.ss.base = 0;
    sregs.ss.limit = std.math.maxInt(u32);
    sregs.ss.g = 1;

    sregs.cs.db = 1;
    sregs.ss.db = 1;
    sregs.cr0 |= 1; // enable protected mode
    ret = ioctl(vcpu, c.KVM_SET_SREGS, @intFromPtr(&sregs));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to set sregs: {}", .{os.errno(ret)});
        return error.REGS;
    }

    // setup general regs
    var regs: c.kvm_regs = undefined;
    ret = ioctl(vcpu, c.KVM_GET_REGS, @intFromPtr(&regs));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to get regs: {}", .{os.errno(ret)});
        return error.REGS;
    }

    regs.rip = 0x100000; // the location protected mode entry
    regs.rsi = 0x10000; // the location of boot_param

    ret = ioctl(vcpu, c.KVM_SET_REGS, @intFromPtr(&regs));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to set regs: {}", .{os.errno(ret)});
        return error.REGS;
    }
}

var history_ins: [20]u64 = undefined;
var pos: u64 = 0;

pub fn record_ins(vcpu: os.fd_t, p: ?*const c.kvm_debug_exit_arch) !void {
    const rip = if (p) |ctx|
        ctx.pc
    else blk: {
        var regs: c.kvm_regs = undefined;
        const ret = ioctl(vcpu, c.KVM_GET_REGS, @intFromPtr(&regs));
        if (os.errno(ret) != .SUCCESS) {
            log.err("failed to get regs: {}", .{os.errno(ret)});
            return error.REGS;
        }
        break :blk regs.rip;
    };

    history_ins[pos % history_ins.len] = rip;
    pos += 1;
}

pub fn dump_vcpu(vcpu: os.fd_t) !void {
    const ram = kvm.getMem();
    var sregs: c.kvm_sregs = undefined;
    var ret = ioctl(vcpu, c.KVM_GET_SREGS, @intFromPtr(&sregs));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to get sregs: {}", .{os.errno(ret)});
        return error.REGS;
    }
    var regs: c.kvm_regs = undefined;
    ret = ioctl(vcpu, c.KVM_GET_REGS, @intFromPtr(&regs));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to get regs: {}", .{os.errno(ret)});
        return error.REGS;
    }

    log.debug("sp=0x{X}", .{regs.rsp});

    // dump history instructions
    var i = pos -| history_ins.len;
    while (i != pos) : (i += 1) {
        const idx = i % history_ins.len;
        const ip = history_ins[idx];
        log.debug("{}: ip=0x{X}", .{ idx, ip });
        dump_ins(ip, ram);
    }
}

fn dump_ins(base: u64, ram: []const u8) void {
    dprint("Code:", .{});
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        const ip = base + i;
        dprint(" {x:0>2}", .{ram[ip]});
    }
    dprint("\n\n", .{});
}
