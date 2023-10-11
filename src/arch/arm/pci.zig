const std = @import("std");
const root = @import("root");
const pci = root.pci;
const mmio = root.mmio;
const libfdt = @cImport({
    @cInclude("libfdt.h");
});
const check = @import("../../helpers.zig").check_non_zero;

const UnitAddr = packed struct {
	hi: u32,
	mid: u32,
	lo: u32,
};

const IrqMask = packed struct {
	pci_addr: UnitAddr,
	pci_pin: u32,
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

    try check(libfdt.fdt_begin_node(dts, "pci"));

    try check(libfdt.fdt_property(dts, "device_type", "pci", "pci".len + 1));
    try check(libfdt.fdt_property(dts, "compatible", "pci-host-ecam-generic", "pci-host-ecam-generic".len + 1));
    try check(libfdt.fdt_property_cell(dts, "#address-cells", 3));
    try check(libfdt.fdt_property_cell(dts, "#size-cells", 2));
    try check(libfdt.fdt_property_cell(dts, "#interrupt-cells", 1));
    try check(libfdt.fdt_property(dts, "reg", &cfg_reg, @sizeOf(@TypeOf(cfg_reg))));
    try check(libfdt.fdt_property(dts, "bus-range", &bug_range, @sizeOf(@TypeOf(bug_range))));
    try check(libfdt.fdt_property(dts, "ranges", &ranges, @sizeOf(@TypeOf(ranges))));

    try check(libfdt.fdt_end_node(dts));

}