const std = @import("std");
const kvm = @import("root").kvm;
const root = @import("root");
const c = root.c;
const ioctl = os.linux.ioctl;
const libfdt = @cImport({
    @cInclude("libfdt.h");
});
const os = std.os;
const check = @import("../../helpers.zig").check_non_zero;
const log = std.log;
const mmio = root.mmio;
const init = @import("init.zig");
const gicv2m = @import("gicv2m.zig");

pub const phandle = 1;
pub const msi_phandle = 2;

pub const irq_type_spi = 0;
pub const irq_type_ppi = 1;

pub const irq_edge_rising = 1;
pub const irq_edge_falling = 2;
pub const irq_level_high = 4;
pub const irq_level_low = 8;

pub const irq_spi_base = 32;

pub fn create(dts: ?*anyopaque, num_cores: usize) !os.fd_t {
    return create_gicv3(dts, num_cores) catch try create_gicv2(dts);
}

fn create_gicv2(dts: ?*anyopaque) !os.fd_t {
    const vm = kvm.getVM();
    const gic_dist_size = 0x10000;
    const gic_dist_base = mmio.alloc_space(gic_dist_size);
    const gic_cpu_size = 0x20000;
    const gic_cpu_base = mmio.alloc_space(gic_cpu_size);
    const reg = [_]u64{ libfdt.cpu_to_fdt64(gic_dist_base), libfdt.cpu_to_fdt64(gic_dist_size), libfdt.cpu_to_fdt64(gic_cpu_base), libfdt.cpu_to_fdt64(gic_cpu_size) };

    var dev = c.kvm_create_device{
        .flags = 0,
        .type = c.KVM_DEV_TYPE_ARM_VGIC_V2,
        .fd = 0,
    };
    try check(ioctl(vm, c.KVM_CREATE_DEVICE, @intFromPtr(&dev)));
    errdefer os.close(@intCast(dev.fd));

    const cpu = c.kvm_device_attr{
        .group = c.KVM_DEV_ARM_VGIC_GRP_ADDR,
        .attr = c.KVM_VGIC_V2_ADDR_TYPE_CPU,
        .addr = @intFromPtr(&gic_cpu_base),
        .flags = 0,
    };
    try check(ioctl(@intCast(dev.fd), c.KVM_SET_DEVICE_ATTR, @intFromPtr(&cpu)));

    const dist = c.kvm_device_attr{
        .group = c.KVM_DEV_ARM_VGIC_GRP_ADDR,
        .attr = c.KVM_VGIC_V2_ADDR_TYPE_DIST,
        .addr = @intFromPtr(&gic_dist_base),
        .flags = 0,
    };
    try check(ioctl(@intCast(dev.fd), c.KVM_SET_DEVICE_ATTR, @intFromPtr(&dist)));

    try gicv2m.init();
    const msi_reg = [_]u64{ libfdt.cpu_to_fdt64(gicv2m.region_start), libfdt.cpu_to_fdt64(gicv2m.region_size) };

    try check(libfdt.fdt_begin_node(dts, "intc"));
    try check(libfdt.fdt_property(
        dts,
        "compatible",
        "arm,cortex-a15-gic",
        "arm,cortex-a15-gic".len + 1,
    ));
    try check(libfdt.fdt_property_cell(dts, "#interrupt-cells", 3));
    try check(libfdt.fdt_property(dts, "interrupt-controller", null, 0));
    try check(libfdt.fdt_property_cell(dts, "#address-cells", 2));
    try check(libfdt.fdt_property_cell(dts, "#size-cells", 2));
    try check(libfdt.fdt_property_cell(dts, "phandle", phandle));
    try check(libfdt.fdt_property(dts, "reg", &reg, @sizeOf(@TypeOf(reg))));

    {
        try check(libfdt.fdt_property(dts, "ranges", null, 0));
        try check(libfdt.fdt_begin_node(dts, "msic"));

        try check(libfdt.fdt_property(dts, "msi-controller", null, 0));
        try check(libfdt.fdt_property(
            dts,
            "compatible",
            "arm,gic-v2m-frame",
            "arm,gic-v2m-frame".len + 1,
        ));
        try check(libfdt.fdt_property_cell(dts, "phandle", msi_phandle));
        try check(libfdt.fdt_property(dts, "reg", &msi_reg, @sizeOf(@TypeOf(msi_reg))));

        try check(libfdt.fdt_end_node(dts));
    }

    try check(libfdt.fdt_end_node(dts));

    return @intCast(dev.fd);
}

fn create_gicv3(dts: ?*anyopaque, num_cores: usize) !os.fd_t {
    const vm = kvm.getVM();
    const gic_dist_size = 0x10000;
    const gic_dist_base = mmio.alloc_space(gic_dist_size);
    const gic_redist_size = num_cores * 0x20000;
    const gic_redist_base = mmio.alloc_space(gic_redist_size);
    const reg = [_]u64{ libfdt.cpu_to_fdt64(gic_dist_base), libfdt.cpu_to_fdt64(gic_dist_size), libfdt.cpu_to_fdt64(gic_redist_base), libfdt.cpu_to_fdt64(gic_redist_size) };

    var dev = c.kvm_create_device{
        .flags = 0,
        .type = c.KVM_DEV_TYPE_ARM_VGIC_V3,
        .fd = 0,
    };
    try check(ioctl(vm, c.KVM_CREATE_DEVICE, @intFromPtr(&dev)));
    errdefer os.close(@intCast(dev.fd));

    const redist = c.kvm_device_attr{
        .group = c.KVM_DEV_ARM_VGIC_GRP_ADDR,
        .attr = c.KVM_VGIC_V3_ADDR_TYPE_REDIST,
        .addr = @intFromPtr(&gic_redist_base),
        .flags = 0,
    };
    try check(ioctl(@intCast(dev.fd), c.KVM_SET_DEVICE_ATTR, @intFromPtr(&redist)));

    const dist = c.kvm_device_attr{
        .group = c.KVM_DEV_ARM_VGIC_GRP_ADDR,
        .attr = c.KVM_VGIC_V3_ADDR_TYPE_DIST,
        .addr = @intFromPtr(&gic_dist_base),
        .flags = 0,
    };
    try check(ioctl(@intCast(dev.fd), c.KVM_SET_DEVICE_ATTR, @intFromPtr(&dist)));

    try check(libfdt.fdt_begin_node(dts, "intc"));
    try check(libfdt.fdt_property(
        dts,
        "compatible",
        "arm,gic-v3",
        "arm,gic-v3".len + 1,
    ));
    try check(libfdt.fdt_property_cell(dts, "#interrupt-cells", 3));
    try check(libfdt.fdt_property(dts, "interrupt-controller", null, 0));
    try check(libfdt.fdt_property_cell(dts, "#address-cells", 2));
    try check(libfdt.fdt_property_cell(dts, "#size-cells", 2));
    try check(libfdt.fdt_property_cell(dts, "phandle", phandle));
    try check(libfdt.fdt_property(dts, "reg", &reg, @sizeOf(@TypeOf(reg))));
    try check(libfdt.fdt_end_node(dts));

    return @intCast(dev.fd);
}
