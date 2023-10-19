const std = @import("std");
const root = @import("root");
const pci = root.pci;
const mmio = root.mmio;
const gic = @import("gic.zig");
const libfdt = @cImport({
    @cInclude("libfdt.h");
});
const check = @import("../../helpers.zig").check_non_zero;

const UnitAddr = packed struct {
    hi: u32,
    mid: u32,
    lo: u32,
};

const Irq = packed struct {
    pci_addr: UnitAddr,
    pci_pin: u32,
};

const GicIrq = packed struct {
    phandle: u32,
    addr_hi: u32,
    addr_lo: u32,
    type: u32,
    num: u32,
    flags: u32,
};

const IrqMap = packed struct {
    pci_irq: Irq,
    gic_irq: GicIrq,
};

const Range = packed struct {
    pci_addr: UnitAddr,
    cpu_addr: u64,
    length: u64,
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
            .cpu_addr = libfdt.cpu_to_fdt64(mmio.GAP_START + mmio.GAP_SIZE),
            .length = libfdt.cpu_to_fdt64(pci.addrspace_size),
        },
    };
    var buf: [4096]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const wr = fbs.writer();
    const pci_devs = pci.registered_devs();
    for (pci_devs, 0..) |d, i| {
        try wr.writeAll(std.mem.asBytes(&IrqMap{
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
        })[0 .. @bitSizeOf(IrqMap) / 8]);
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
    try check(libfdt.fdt_property(dts, "ranges", &ranges, @bitSizeOf(@TypeOf(ranges)) / 8));
    try check(libfdt.fdt_property_cell(dts, "msi-parent", gic.msi_phandle));
    if (pci_devs.len > 0) {
        const written = fbs.getWritten();
        try check(libfdt.fdt_property(dts, "interrupt-map", written.ptr, @intCast(written.len)));
        try check(libfdt.fdt_property(dts, "interrupt-map-mask", &irq_mask, @bitSizeOf(@TypeOf(irq_mask)) / 8));
    }

    try check(libfdt.fdt_end_node(dts));
}
