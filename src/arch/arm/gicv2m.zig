const std = @import("std");
const root = @import("root");
const mmio = root.mmio;
const io = root.io;
const irq = root.irq;

pub const region_size = 0x1000;
pub var region_start: u64 = undefined;

var first_spi: u32 = undefined;
const num_spis = 64;

pub fn init() !void {
    region_start = mmio.alloc_space(region_size);
    try mmio.register_handler(region_start, region_size, handler, null);

    first_spi = irq.alloc();
    // reserve spis
    for (0..num_spis) |_| {
        _ = irq.alloc();
    }
}

fn handler(_: ?*anyopaque, offset: u64, op: io.Operation, data: []u8) !void {
    const msi_typer = 0x8;
    const msi_iidr = 0xfcc;

    switch (op) {
        .Write => unreachable,
        .Read => switch (offset) {
            msi_typer => {
                const val: u32 = (first_spi << 16) | num_spis;
                @memcpy(data, std.mem.asBytes(&val));
            },
            msi_iidr => @memset(data, 0),
            else => {},
        },
    }
}
