const std = @import("std");
const libfdt = @cImport({
    @cInclude("libfdt.h");
});
const root = @import("root");
const init = @import("init.zig");
const mmio = root.mmio;
const check = @import("../../helpers.zig").check_non_zero;
const v8250 = @import("../../hw/8250.zig");
const io = @import("../../io.zig");
const gic = @import("gic.zig");
const irq = @import("../../irq.zig");

fn handle(offset: u64, op: io.Operation, len: u32, val: []u8) !void {
    return v8250.handle(@intCast(offset), op, 1, len, val[0..len]);
}

pub fn create(dts: ?*anyopaque) !void {
    const reg_size = 0x8;
    const reg_base = mmio.alloc_space(reg_size);
    const reg = [_]u64{ libfdt.cpu_to_fdt64(reg_base), libfdt.cpu_to_fdt64(reg_size) };
    const irq_no = irq.alloc();
    const irqs = [_]u32{ libfdt.cpu_to_fdt32(gic.irq_type_spi), libfdt.cpu_to_fdt32(irq_no - gic.irq_spi_base), libfdt.cpu_to_fdt32(gic.irq_level_high) };

    try mmio.register_handler(reg_base, reg_size, handle);
    v8250.setup_irq(irq_no);

    try check(libfdt.fdt_begin_node(dts, "serial"));
    try check(libfdt.fdt_property(
        dts,
        "compatible",
        "ns16550",
        "ns16550".len + 1,
    ));
    try check(libfdt.fdt_property(dts, "reg", &reg, @sizeOf(@TypeOf(reg))));
    try check(libfdt.fdt_property(dts, "clock-frequency", &libfdt.cpu_to_fdt32(1843200), 4));
    try check(libfdt.fdt_property(dts, "interrupts", &irqs, @sizeOf(@TypeOf(irqs))));
    try check(libfdt.fdt_end_node(dts));
}
