const std = @import("std");
const root = @import("root");
const mmio = @import("mmio.zig");
const io = @import("io.zig");
const builtin = @import("builtin");
const mem = std.mem;
pub const c = @cImport({
    @cInclude("linux/pci_regs.h");
});

pub const cfg_size = 1 << 28;
pub var cfg_start: ?u64 = null;

pub const addrspace_start = 4 << 32;
pub const addrspace_size = 1 << 32;
var free_space_addr: u64 = addrspace_start;

fn alloc_space(size: u64) u64 {
    std.debug.assert(size & ((1 << 12) - 1) == 0);
    if (free_space_addr + size > addrspace_start + addrspace_size) @panic("not enough PCI address space");

    defer free_space_addr += size;
    return free_space_addr;
}

pub fn init() !void {
    cfg_start = mmio.alloc_space(cfg_size);
    try mmio.register_handler(cfg_start.?, cfg_size, handle, null);
}

pub fn deinit() void {}

const Addr = switch (builtin.cpu.arch.endian()) {
    .Little => packed struct {
        reg_offset: u2,
        register_number: u10,
        function_number: u3,
        device_number: u5,
        bus_number: u8,
        reserved: u3,
        enable_bit: u1,
    },
    .Big => packed struct {
        enable_bit: u1,
        reserved: u3,
        bus_number: u8,
        device_number: u5,
        function_number: u3,
        register_number: u10,
        reg_offset: u2,
    },
};

pub const COMM = extern struct {
    vendor_id: u16,
    device_id: u16,
    command: u16,
    status: u16,
    revision_id: u8,
    class: [3]u8,
    cacheline_size: u8,
    latency_timer: u8,
    header_type: u8,
    bist: u8,
    bar: [6]u32,
    card_bus: u32,
    subsys_vendor_id: u16,
    subsys_id: u16,
    exp_rom_bar: u32,
    capabilities: u8,
    reserved1: [3]u8,
    reserved2: u32,
    irq_line: u8,
    irq_pin: u8,
    min_gnt: u8,
    max_lat: u8,
};

pub const msix_table_entry = extern struct {
    addr_lo: u32,
    addr_hi: u32,
    data: u32,
    ctrl: u32,
};

pub const msix_cap = extern struct {
    cap_vndr: u8,
    cap_next: u8,
    ctrl: u16,
    table_offset: u32,
    pba_offset: u32,
};

const CFG = extern struct {
    comm: COMM,
    free: [4096 - @sizeOf(COMM)]u8,
};

const CapHeader = packed struct {
    id: u8,
    next: u8,
};

pub const H = *const fn (?*anyopaque, u64, io.Operation, []u8) anyerror!void;

pub const Dev = struct {
    cfg: CFG,
    bar_addr: [6]?u64 = .{null} ** 6,
    bar_size: [6]?u64 = .{null} ** 6,
    bar_handle: [6]?struct { h: H, ctx: ?*anyopaque } = .{null} ** 6,

    last_cap: ?*CapHeader = null,
    cap_allocator: mem.Allocator,

    const Self = @This();

    pub fn add_cap(self: *Self, comptime T: type) !*T {
        const ret = try self.cap_allocator.create(T);
        if (self.last_cap) |cap| {
            cap.next = @intCast(@intFromPtr(ret) - @intFromPtr(&self.cfg));
        } else {
            const offset = @intFromPtr(ret) - @intFromPtr(&self.cfg);
            std.debug.assert(offset == @offsetOf(CFG, "free"));
            self.cfg.comm.status = mem.nativeToLittle(u16, c.PCI_STATUS_CAP_LIST);
            self.cfg.comm.capabilities = @intCast(offset);
        }
        self.last_cap = @ptrCast(ret);
        return ret;
    }

    pub fn allocate_bar(self: *Self, i: usize, size: u64, h: H, ctx: ?*anyopaque) !u64 {
        if (self.bar_addr[i] == null) {
            const pci_start = alloc_space(size);

            const cpu_start = mmio.GAP_START + mmio.GAP_SIZE + (pci_start - addrspace_start); // pci space follows mmio space

            self.bar_addr[i] = pci_start;
            self.bar_size[i] = size;
            self.bar_handle[i] = .{ .h = h, .ctx = ctx };

            try mmio.register_handler(cpu_start, size, h, ctx);

            self.cfg.comm.bar[i * 2] = mem.nativeToLittle(u32, @as(u32, @truncate(pci_start)) | c.PCI_BASE_ADDRESS_SPACE_MEMORY | c.PCI_BASE_ADDRESS_MEM_TYPE_64);
            self.cfg.comm.bar[i * 2 + 1] = mem.nativeToLittle(u32, @as(u32, @truncate(pci_start >> 32)));
            return cpu_start;
        } else unreachable;
    }

    pub fn handler(self: *Self, offset: u64, op: io.Operation, data: []u8) !void {
        const S = struct {
            var new_bar_addrs: [6]u64 = undefined;
        };
        switch (offset) {
            c.PCI_BASE_ADDRESS_0...c.PCI_BASE_ADDRESS_5 => {
                const i = (offset - c.PCI_BASE_ADDRESS_0) / (2 * @sizeOf(u32));
                const is_lowpart = (offset - c.PCI_BASE_ADDRESS_0) % (2 * @sizeOf(u32)) == 0;

                if (op == .Write) {
                    if (self.bar_size[i]) |bar_size| {
                        if (mem.eql(u8, data, &.{ 0xff, 0xff, 0xff, 0xff })) {
                            // prepare to query bar size
                            if (is_lowpart) {
                                mem.writeIntLittle(u32, mem.asBytes(&self.cfg)[offset..][0..4], @as(u32, @truncate(~(bar_size - 1) | (self.bar_addr[i].? & 0xf))));
                            } else {
                                mem.writeIntLittle(u32, mem.asBytes(&self.cfg)[offset..][0..4], @as(u32, @truncate(bar_size >> 32)));
                            }
                            return;
                        } else {
                            if (is_lowpart) {
                                S.new_bar_addrs[i] &= 0xffffffff_00000000;
                                S.new_bar_addrs[i] |= (mem.readIntLittle(u32, data[0..4]) & 0xfffffff0);
                            } else {
                                S.new_bar_addrs[i] &= 0x00000000_ffffffff;
                                S.new_bar_addrs[i] |= (@as(u64, mem.readIntLittle(u32, data[0..4])) << 32);

                                const cpu_start = mmio.GAP_START + mmio.GAP_SIZE + (S.new_bar_addrs[i] - addrspace_start); // pci space follows mmio space

                                try mmio.register_handler(cpu_start, self.bar_size[i].?, self.bar_handle[i].?.h, self.bar_handle[i].?.ctx);

                                self.bar_addr[i] = S.new_bar_addrs[i];
                            }
                        }
                    }
                }
            },
            c.PCI_ROM_ADDRESS => if (op == .Write and mem.eql(u8, data, mem.asBytes(&c.PCI_ROM_ADDRESS_MASK))) {
                // Do not support ROM bar yet
                mem.writeIntLittle(u32, data[0..4], 0);
                return;
            },
            else => {},
        }

        switch (op) {
            .Read => @memcpy(data, mem.asBytes(&self.cfg)[offset..][0..data.len]),
            .Write => @memcpy(@constCast(mem.asBytes(&self.cfg))[offset..][0..data.len], data),
        }
    }
};

var devs: [32]Dev = undefined;
var registered_num: usize = 0;

pub fn registered_devs() []Dev {
    return devs[0..registered_num];
}

pub fn register(vendor_id: u16, device_id: u16, subsys_vendor_id: u16, subsys_id: u16, class: u24, irq: u32) !*Dev {
    if (registered_num == 32) {
        return error.TOO_MANY;
    }

    var cap_buf = std.heap.FixedBufferAllocator.init(&devs[registered_num].cfg.free);
    devs[registered_num] = .{
        .cfg = mem.zeroInit(CFG, .{
            .comm = mem.zeroInit(COMM, .{
                .vendor_id = mem.nativeToLittle(u16, vendor_id),
                .device_id = mem.nativeToLittle(u16, device_id),
                .command = c.PCI_COMMAND_IO | c.PCI_COMMAND_MEMORY,
                .header_type = c.PCI_HEADER_TYPE_NORMAL,
                .class = .{ @as(u8, @truncate(class)), @as(u8, @truncate(class >> 8)), @as(u8, @truncate(class >> 16)) },
                .subsys_vendor_id = mem.nativeToLittle(u16, subsys_vendor_id),
                .subsys_id = mem.nativeToLittle(u16, subsys_id),
                .irq_line = @as(u8, @intCast(irq)),
                .irq_pin = 1,
            }),
        }),
        .cap_allocator = cap_buf.allocator(),
    };
    defer registered_num += 1;

    return &devs[registered_num];
}

fn handle(_: ?*anyopaque, offset: u64, op: io.Operation, data: []u8) !void {
    const addr: Addr = @bitCast(@as(u32, @truncate(offset)));
    const dev: ?*Dev = if (addr.device_number < registered_num) &devs[addr.device_number] else null;
    const reg_offset: u12 = @truncate(offset);

    switch (op) {
        .Read => if (dev) |d| {
            try d.handler(reg_offset, op, data);
        } else {
            @memset(data, 0xff);
        },

        .Write => if (dev) |d| {
            try d.handler(reg_offset, op, data);
        } else {
            // do nothing
        },
    }

    //std.log.info("dev{}: {} 0x{x} {any}", .{ addr.device_number, op, reg_offset, data });
}
