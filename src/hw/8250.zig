const std = @import("std");
const log = std.log;
const io = @import("../io.zig");
const dprint = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;
const kvm = @import("root").kvm;

var irq: u32 = 4;

const RBR = 0;
const THR = 0;
const DLL = 0;
const IER = 1;
const DLM = 1;
const IIR = 2;
const FCR = 2;
const LCR = 3;
const MCR = 4;
const LSR = 5;
const MSR = 6;
const SCR = 7;

const UART_LSR_DR = 0x1;
const UART_LSR_BI = 0x10;
const UART_LSR_THRE = 0x20;
const UART_LSR_TEMT = 0x40;
const UART_IER_THRI = 0x2;
const UART_IER_RDI = 0x1;

var registers = mem.zeroes([8]u8);
var prevIir: bool = false;

const BUF_SIZE = 64;
var pending: [BUF_SIZE]u8 = undefined;
var rIdx: u6 = 0;
var wIdx: u6 = 0;

var mutex = std.Thread.Mutex{};

pub fn setup_irq(n: u32) void {
    irq = n;
}

pub fn handle(offset: u16, op: io.Operation, val: []u8) anyerror!void {
    mutex.lock();
    defer mutex.unlock();

    switch (op) {
        .Read => switch (offset) {
            RBR => {
                if (rIdx != wIdx) {
                    val[0] = pending[rIdx];
                    rIdx +%= 1;
                }
                if (rIdx == wIdx) {
                    registers[LSR] &= ~@as(u8, UART_LSR_DR | UART_LSR_BI);
                }
            },
            else => val[0] = registers[offset],
        },
        .Write => switch (offset) {
            THR => {
                registers[LSR] |= @as(u8, UART_LSR_TEMT | UART_LSR_THRE);
                //log.info("ier: {X}, lsr: {X}", .{ registers[IER], registers[LSR] });
                dprint("{s}", .{val});
            },
            else => registers[offset] = val[0],
        },
    }

    if (op == .Read) {
        //log.info("{} {} 0x{X}", .{ op, offset, val[0] });
    }

    try updateIrq();
}

fn updateIrq() !void {
    var iir = false;

    // Data ready and rcv interrupt enabled
    if (registers[IER] & UART_IER_RDI == UART_IER_RDI and registers[LSR] & UART_LSR_DR == UART_LSR_DR) {
        iir = true;
    }
    // Transmitter empty and interrupt enabled
    if (registers[IER] & UART_IER_THRI == UART_IER_THRI and registers[LSR] & UART_LSR_TEMT == UART_LSR_TEMT) {
        iir = true;
    }

    if (prevIir == false and iir == true) {
        try kvm.setIrqLevel(irq, 1);
    } else if (prevIir == true and iir == false) {
        try kvm.setIrqLevel(irq, 0);
    }

    prevIir = iir;
}

pub fn forwardStdin(line: []const u8) !void {
    mutex.lock();
    defer mutex.unlock();
    var sysrq = false;
    const chars = line;

    // ctrl+v as prefix
    if (mem.startsWith(u8, chars, "\x16")) {
        log.info("enter sysrq", .{});
        sysrq = true;
    }

    for (chars) |char| {
        //log.info("get 0x{x}", .{char});
        pending[wIdx] = char;
        wIdx +%= 1;
    }

    registers[LSR] |= UART_LSR_DR;
    if (sysrq) registers[LSR] |= UART_LSR_BI;
    try updateIrq();
}
