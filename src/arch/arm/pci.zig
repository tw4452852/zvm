const std = @import("std");
const root = @import("root");
const pci = root.pci;
const mmio = root.mmio;
const gic = @import("gic.zig");
const libfdt = @cImport({
    @cInclude("libfdt.h");
});
const check = @import("../../helpers.zig").check_non_zero;

// we use extern here to preserve fields order
const UnitAddr = extern struct {
    hi: u32,
    mid: u32,
    lo: u32,
};

const Irq = extern struct {
    pci_addr: UnitAddr,
    pci_pin: u32,
};

const GicIrq = extern struct {
    phandle: u32,
    addr_hi: u32,
    addr_lo: u32,
    type: u32,
    num: u32,
    flags: u32,
};

const IrqMap = extern struct {
    pci_irq: Irq,
    gic_irq: GicIrq,
};

const Range = extern struct {
    pci_addr: UnitAddr,
    // we have to split u64 to avoid padding here because UnitAddr is 32bit aligned
    cpu_addr_hi: u32,
    cpu_addr_lo: u32,
    length_hi: u32,
    length_lo: u32,
};

const AddrType = enum(u32) {
    config,
    io,
    mem32,
    mem64,
};

pub fn generate_fdt_node(dts: ?*anyopaque) !void {
    const bug_range = [_]u32{ libfdt.cpu_to_fdt32(0), libfdt.cpu_to_fdt32(0) };
    const cfg_reg = [_]u64{ libfdt.cpu_to_fdt64(pci.cfg_start.?), libfdt.cpu_to_fdt64(pci.cfg_size) };
    const ranges = [_]Range{
        .{
            .pci_addr = .{
                .hi = libfdt.cpu_to_fdt32(@intFromEnum(AddrType.mem64) << 24),
                .mid = libfdt.cpu_to_fdt32(pci.addrspace_start >> 32),
                .lo = libfdt.cpu_to_fdt32(pci.addrspace_start & 0xffffffff),
            },
            .cpu_addr_lo = libfdt.cpu_to_fdt32(@truncate(mmio.GAP_START + mmio.GAP_SIZE)),
            .cpu_addr_hi = libfdt.cpu_to_fdt32((mmio.GAP_START + mmio.GAP_SIZE) >> 32),
            .length_lo = libfdt.cpu_to_fdt32(@truncate(pci.addrspace_size)),
            .length_hi = libfdt.cpu_to_fdt32(pci.addrspace_size >> 32),
        },
    };

    var irq_maps: [64]IrqMap = undefined;
    const pci_devs = pci.registered_devs();
    for (pci_devs, 0..) |d, i| {
        irq_maps[i] = .{
            .pci_irq = .{
                .pci_addr = .{
                    .hi = libfdt.cpu_to_fdt32(@as(u32, @intCast(i << 11))), // device number
                    .mid = 0,
                    .lo = 0,
                },
                .pci_pin = libfdt.cpu_to_fdt32(d.cfg.comm.irq_pin),
            },
            .gic_irq = .{
                .phandle = libfdt.cpu_to_fdt32(gic.phandle),
                .addr_hi = 0,
                .addr_lo = 0,
                .type = libfdt.cpu_to_fdt32(gic.irq_type_spi),
                .num = libfdt.cpu_to_fdt32(d.cfg.comm.irq_line - gic.irq_spi_base),
                .flags = libfdt.cpu_to_fdt32(gic.irq_level_high),
            },
        };
    }
    const irq_mask: Irq = .{
        .pci_addr = .{
            .hi = libfdt.cpu_to_fdt32(@as(u32, @intCast(0x1f << 11))), // device part mask
            .mid = 0,
            .lo = 0,
        },
        .pci_pin = libfdt.cpu_to_fdt32(7),
    };

    try check(libfdt.fdt_begin_node(dts, "pci"));

    try check(libfdt.fdt_property(dts, "device_type", "pci", "pci".len + 1));
    try check(libfdt.fdt_property(dts, "compatible", "pci-host-ecam-generic", "pci-host-ecam-generic".len + 1));
    try check(libfdt.fdt_property_cell(dts, "#address-cells", 3));
    try check(libfdt.fdt_property_cell(dts, "#size-cells", 2));
    try check(libfdt.fdt_property_cell(dts, "#interrupt-cells", 1));
    try check(libfdt.fdt_property(dts, "reg", &cfg_reg, @sizeOf(@TypeOf(cfg_reg))));
    try check(libfdt.fdt_property(dts, "bus-range", &bug_range, @sizeOf(@TypeOf(bug_range))));
    try check(libfdt.fdt_property(dts, "ranges", &ranges, @sizeOf(@TypeOf(ranges))));
    try check(libfdt.fdt_property_cell(dts, "msi-parent", gic.msi_phandle));
    if (pci_devs.len > 0) {
        try check(libfdt.fdt_property(dts, "interrupt-map", &irq_maps, @intCast(@sizeOf(@TypeOf(irq_maps[0])) * pci_devs.len)));
        try check(libfdt.fdt_property(dts, "interrupt-map-mask", &irq_mask, @sizeOf(@TypeOf(irq_mask))));
    }

    try check(libfdt.fdt_end_node(dts));
}
