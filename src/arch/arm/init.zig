const std = @import("std");
const log = std.log;
const os = std.os;
const fs = std.fs;
const root = @import("root");
const kvm = root.kvm;
const c = root.c;
const ioctl = os.linux.ioctl;
const mmio = root.mmio;
const virtio_mmio = root.virtio_mmio;
const libfdt = @cImport({
    @cInclude("libfdt.h");
});
const check = @import("../../helpers.zig").check_non_zero;
const gic = @import("gic.zig");
const mmio_16550 = @import("mmio_16550.zig");
const mem = std.mem;
const fmt = std.fmt;

var dts: [0x10000]u8 = undefined;
var kernel_addr: u64 = 0x80_000;
var dtb_addr: u64 = undefined;
var gic_fd: os.fd_t = undefined;
var num_cpus: usize = undefined;

pub fn init_vm(num_cores: usize) !void {
    num_cpus = num_cores;
    try check(libfdt.fdt_create(&dts, dts.len));
    try check(libfdt.fdt_finish_reservemap(&dts));

    try check(libfdt.fdt_begin_node(&dts, ""));
    try check(libfdt.fdt_property_cell(&dts, "#address-cells", 2));
    try check(libfdt.fdt_property_cell(&dts, "#size-cells", 2));
    try check(libfdt.fdt_property_cell(&dts, "interrupt-parent", gic.phandle));
    try check(libfdt.fdt_property(&dts, "compatile", "linux,dummy-virt", "linux,dummy-virt".len + 1));

    try generate_cpus_node(num_cores);

    // memory
    const mem_reg = [_]u64{ libfdt.cpu_to_fdt64(0), libfdt.cpu_to_fdt64(kvm.getMem().len) };
    try check(libfdt.fdt_begin_node(&dts, "memory"));
    try check(libfdt.fdt_property(&dts, "device_type", "memory", "memory".len + 1));
    try check(libfdt.fdt_property(&dts, "reg", &mem_reg, @sizeOf(@TypeOf(mem_reg))));
    try check(libfdt.fdt_end_node(&dts));

    // timer
    const cpu_mask = 0xff << 8;
    const timer_irqs = [_]u32{
        libfdt.cpu_to_fdt32(gic.irq_type_ppi),
        libfdt.cpu_to_fdt32(13), // secure physical
        libfdt.cpu_to_fdt32(cpu_mask | gic.irq_level_low),

        libfdt.cpu_to_fdt32(gic.irq_type_ppi),
        libfdt.cpu_to_fdt32(14), // nonsecure physical
        libfdt.cpu_to_fdt32(cpu_mask | gic.irq_level_low),

        libfdt.cpu_to_fdt32(gic.irq_type_ppi),
        libfdt.cpu_to_fdt32(11), // virtual
        libfdt.cpu_to_fdt32(cpu_mask | gic.irq_level_low),

        libfdt.cpu_to_fdt32(gic.irq_type_ppi),
        libfdt.cpu_to_fdt32(10), // hypervisor physical
        libfdt.cpu_to_fdt32(cpu_mask | gic.irq_level_low),
    };
    try check(libfdt.fdt_begin_node(&dts, "timer"));
    try check(libfdt.fdt_property(&dts, "compatible", "arm,armv8-timer", "arm,armv8-timer".len + 1));
    try check(libfdt.fdt_property(&dts, "interrupts", &timer_irqs, @sizeOf(@TypeOf(timer_irqs))));
    try check(libfdt.fdt_end_node(&dts));

    // PSCI
    try check(libfdt.fdt_begin_node(&dts, "psci"));
    try check(libfdt.fdt_property(&dts, "compatible", "arm,psci", "arm,psci".len + 1));
    try check(libfdt.fdt_property(&dts, "method", "hvc", "hvc".len + 1));
    try check(libfdt.fdt_property_cell(&dts, "cpu_suspend", c.KVM_PSCI_FN_CPU_SUSPEND));
    try check(libfdt.fdt_property_cell(&dts, "cpu_off", c.KVM_PSCI_FN_CPU_OFF));
    try check(libfdt.fdt_property_cell(&dts, "cpu_on", c.KVM_PSCI_FN_CPU_ON));
    try check(libfdt.fdt_property_cell(&dts, "migrate", c.KVM_PSCI_FN_MIGRATE));
    try check(libfdt.fdt_end_node(&dts));

    gic_fd = try gic.create(&dts, num_cores);
    try mmio_16550.create(&dts);
}

fn generate_cpus_node(num_cores: usize) !void {
    try check(libfdt.fdt_begin_node(&dts, "cpus"));
    try check(libfdt.fdt_property_cell(&dts, "#address-cells", 1));
    try check(libfdt.fdt_property_cell(&dts, "#size-cells", 0));

    var buf: [16]u8 = undefined;
    for (0..num_cores) |i| {
        const mpidr: u32 = @as(u32, @intCast(i));

        const name = try fmt.bufPrintZ(&buf, "cpu{}", .{i});
        try check(libfdt.fdt_begin_node(&dts, name.ptr));
        try check(libfdt.fdt_property(&dts, "device_type", "cpu", "cpu".len + 1));
        try check(libfdt.fdt_property(&dts, "compatible", "arm,arm-v8", "arm,arm-v8".len + 1));
        try check(libfdt.fdt_property(&dts, "enable-method", "psci", "psci".len + 1));
        try check(libfdt.fdt_property_cell(&dts, "reg", mpidr));

        try check(libfdt.fdt_end_node(&dts));
    }

    try check(libfdt.fdt_end_node(&dts));
}

pub fn load_kernel(kernel_path: []const u8, cmd: *const root.Cmdline, initrd_path: ?[]const u8) !void {
    var ram = kvm.getMem();
    const f = try fs.cwd().openFile(kernel_path, .{});
    defer f.close();

    const fsize = (try f.stat()).size;
    const data = try os.mmap(null, fsize, c.PROT_READ, c.MAP_PRIVATE, f.handle, 0);

    // get load offset
    const HEADER = struct {
        code0: u32,
        code1: u32,
        text_offset: u64,
        image_size: u64,
        flags: u64,
        res0: u64,
        res1: u64,
        res2: u64,
        magic: u32,
        res3: u32,
    };
    const hdr: *HEADER = @ptrCast(data.ptr);
    if (!mem.eql(u8, mem.asBytes(&hdr.magic), "ARM\x64")) {
        log.err("invalid magic number: {X}", .{hdr.magic});
        return error.BADIMAGE;
    }
    if (hdr.image_size > 0) kernel_addr = hdr.text_offset;

    // load kernel image
    if (kernel_addr + fsize >= ram.len) {
        log.err("not enough memory for kernel", .{});
        return error.KERNEL;
    }
    const kernel_end = kernel_addr + fsize;
    @memcpy(ram.ptr + kernel_addr, data[0..fsize]);
    log.info("load kernel to 0x{x}", .{kernel_addr});

    // determine the dtb load address from the end of ram backwards
    const max_dtb_size = 0x200_000; // 2M, also the alignment
    dtb_addr = ram.len - max_dtb_size;
    if (dtb_addr < kernel_end) {
        log.err("dtb overlaps with kernel", .{});
        return error.DTB;
    }

    try check(libfdt.fdt_begin_node(&dts, "chosen"));
    // copy cmdline to dtb
    const cmdline = cmd.constSlice();
    try check(libfdt.fdt_property(&dts, "bootargs", cmdline.ptr, @intCast(cmdline.len + 1)));
    // stdout
    try check(libfdt.fdt_property(&dts, "stdout-path", "/serial", "/serial".len + 1));

    // load initrd
    if (initrd_path) |path| {
        const initrd_f = try fs.cwd().openFile(path, .{});
        defer initrd_f.close();

        const initrd_size = (try initrd_f.stat()).size;

        const initrd_addr = mem.alignBackward(u64, dtb_addr - initrd_size, 4);
        if (initrd_addr < kernel_end) {
            log.err("initrd overlaps with kernel", .{});
            return error.INITRD;
        }

        _ = try initrd_f.readAll((ram.ptr + initrd_addr)[0..initrd_size]);

        try check(libfdt.fdt_property(&dts, "linux,initrd-start", &libfdt.cpu_to_fdt64(initrd_addr), 8));
        try check(libfdt.fdt_property(&dts, "linux,initrd-end", &libfdt.cpu_to_fdt64(initrd_addr + initrd_size), 8));

        log.info("load initrd to 0x{x}", .{initrd_addr});
    }

    try check(libfdt.fdt_end_node(&dts)); // end "chosen" node

    // virtio mmio devices
    var virtio_mmio_dev: ?*virtio_mmio.Dev = virtio_mmio.get_registered_devs();
    while (virtio_mmio_dev) |dev| : (virtio_mmio_dev = dev.next) {
        const mems = [_]u64{ libfdt.cpu_to_fdt64(dev.start), libfdt.cpu_to_fdt64(dev.len) };
        const irqs = [_]u32{ libfdt.cpu_to_fdt32(gic.irq_type_spi), libfdt.cpu_to_fdt32(dev.irq - gic.irq_spi_base), libfdt.cpu_to_fdt32(gic.irq_edge_rising) };

        try check(libfdt.fdt_begin_node(&dts, dev.name.ptr));
        try check(libfdt.fdt_property(&dts, "compatible", "virtio,mmio", "virtio,mmio".len + 1));
        try check(libfdt.fdt_property(&dts, "reg", &mems, @sizeOf(@TypeOf(mems))));
        try check(libfdt.fdt_property(&dts, "interrupts", &irqs, @sizeOf(@TypeOf(irqs))));
        try check(libfdt.fdt_end_node(&dts));
    }

    // load dtb, dtb should be finalized at this point
    try check(libfdt.fdt_end_node(&dts)); // end top level node
    try check(libfdt.fdt_finish(&dts));
    try check(libfdt.fdt_open_into(&dts, ram.ptr + dtb_addr, max_dtb_size));
    try check(libfdt.fdt_pack(ram.ptr + dtb_addr));
    log.info("load dtb to 0x{x}", .{dtb_addr});

    try std.fs.cwd().writeFile("dtb", (ram.ptr + dtb_addr)[0..max_dtb_size]);
}

pub fn init_vcpu(vcpu: os.fd_t, i: usize) !void {
    var data: u64 = undefined;
    var vcpu_init = mem.zeroInit(c.kvm_vcpu_init, .{
        .target = c.KVM_ARM_TARGET_GENERIC_V8,
    });
    var reg = mem.zeroInit(c.kvm_one_reg, .{
        .addr = @intFromPtr(&data),
    });

    if (i > 0) vcpu_init.features[0] |= (1 << c.KVM_ARM_VCPU_POWER_OFF);
    try check(ioctl(vcpu, c.KVM_ARM_VCPU_INIT, @intFromPtr(&vcpu_init)));

    // mask all interrupts
    data = c.PSR_D_BIT | c.PSR_A_BIT | c.PSR_I_BIT | c.PSR_F_BIT | c.PSR_MODE_EL1h;
    reg.id = c.KVM_REG_ARM64 | c.KVM_REG_ARM_CORE | (@offsetOf(c.user_pt_regs, "pstate") / 4) | c.KVM_REG_SIZE_U64;
    try check(ioctl(vcpu, c.KVM_SET_ONE_REG, @intFromPtr(&reg)));

    if (i == 0) {
        // set x0 as dtb address
        data = dtb_addr;
        reg.id = c.KVM_REG_ARM64 | c.KVM_REG_ARM_CORE | (0) | c.KVM_REG_SIZE_U64;
        try check(ioctl(vcpu, c.KVM_SET_ONE_REG, @intFromPtr(&reg)));

        // set pc for the first core
        data = kernel_addr;
        reg.id = c.KVM_REG_ARM64 | c.KVM_REG_ARM_CORE | (@offsetOf(c.user_pt_regs, "pc") / 4) | c.KVM_REG_SIZE_U64;
        try check(ioctl(vcpu, c.KVM_SET_ONE_REG, @intFromPtr(&reg)));
    }

    // After all cpus are initialized, let's initialize vgic explictly
    if (i == num_cpus - 1) {
        // finalize gic initilization
        const vgic_init: c.kvm_device_attr = .{
            .group = c.KVM_DEV_ARM_VGIC_GRP_CTRL,
            .attr = c.KVM_DEV_ARM_VGIC_CTRL_INIT,
            .addr = 0,
            .flags = 0,
        };

        try check(ioctl(gic_fd, c.KVM_SET_DEVICE_ATTR, @intFromPtr(&vgic_init)));
    }
}

pub fn dump_vcpu(_: os.fd_t) !void {
    @panic("todo");
}

pub fn record_ins(vcpu: os.fd_t, arch: ?*const c.kvm_debug_exit_arch) !void {
    if (arch) |_| {
        // get pc
        var pc: u64 = undefined;
        const reg: c.kvm_one_reg = .{
            .id = c.KVM_REG_ARM64 | c.KVM_REG_ARM_CORE | (@offsetOf(c.user_pt_regs, "pc") / 4) | c.KVM_REG_SIZE_U64,
            .addr = @intFromPtr(&pc),
        };
        try check(ioctl(vcpu, c.KVM_GET_ONE_REG, @intFromPtr(&reg)));
        log.debug("pc: 0x{x}", .{pc - kernel_addr});
    }
}

pub fn setIrqLevelInner(irq: u32, level: u1) !void {
    const vm = kvm.getVM();
    const irq_level: c.kvm_irq_level = .{ .unnamed_0 = .{
        .irq = (1 << 24) | irq,
    }, .level = level };

    const ret = ioctl(vm, c.KVM_IRQ_LINE, @intFromPtr(&irq_level));
    //log.info("tw; set irq{}, level = {}", .{ irq_level.unnamed_0.irq, irq_level.level });
    if (os.linux.getErrno(ret) != .SUCCESS) {
        log.err("failed to set irq{}, level{}: {}", .{ irq, level, os.linux.getErrno(ret) });
        return error.IRQ;
    }
}
