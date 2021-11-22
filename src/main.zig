const std = @import("std");
const log = std.log;
const os = std.os;
const mem = std.mem;
const process = std.process;
const fmt = std.fmt;
pub const c = @cImport({
    @cInclude("linux/kvm.h");
    @cInclude("linux/kvm_para.h");
    @cInclude("sys/mman.h");
});
const arch = @import("arch/index.zig");
const portio = @import("portio.zig");
const mmio = @import("mmio.zig");
const stdio = @import("stdio.zig");
const vcpu = @import("vcpu.zig");
const virtio_blk = @import("virtio_blk.zig");
pub const kvm = @import("kvm.zig");

pub var enable_debug = false;

pub const MAX_CPUS = 256;

fn usage() !void {
    log.info(
        \\ Usage:
        \\ -kernel [path]
        \\ -initrd [path]
        \\ -cmdline [cmdline]
        \\ -b [block file path]
        \\ -m [memory size, support K/M/G]
        \\ -c [number of core]
        \\ -debug
    , .{});
    return error.USAGE;
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);
    var arg_idx: usize = 1; // skip exe name

    var kernel_file_path: ?[]const u8 = null;
    var initrd_file_path: ?[]const u8 = null;
    var blk_file_path: ?[]const u8 = null;
    var cmdline: []const u8 = "console=ttyS0 panic=1";
    var ram_size: usize = 0x100_00000; // 256M

    var num_cores: u8 = 1;
    while (nextArg(args, &arg_idx)) |arg| {
        if (mem.eql(u8, arg, "-kernel")) {
            kernel_file_path = nextArg(args, &arg_idx) orelse {
                return usage();
            };
        } else if (mem.eql(u8, arg, "-initrd")) {
            initrd_file_path = nextArg(args, &arg_idx) orelse {
                return usage();
            };
        } else if (mem.eql(u8, arg, "-cmdline")) {
            cmdline = nextArg(args, &arg_idx) orelse {
                return usage();
            };
        } else if (mem.eql(u8, arg, "-c")) {
            const s = nextArg(args, &arg_idx) orelse {
                return usage();
            };
            num_cores = try fmt.parseUnsigned(u8, s, 0);
            if (num_cores > MAX_CPUS) {
                log.info("not support {} cpus", .{num_cores});
                return usage();
            }
        } else if (mem.eql(u8, arg, "-debug")) {
            enable_debug = true;
        } else if (mem.eql(u8, arg, "-b")) {
            blk_file_path = nextArg(args, &arg_idx) orelse {
                return usage();
            };
        } else if (mem.eql(u8, arg, "-m")) {
            const ms = nextArg(args, &arg_idx) orelse {
                return usage();
            };
            switch (ms[ms.len - 1]) {
                'K' => ram_size = (try fmt.parseInt(usize, ms[0 .. ms.len - 1], 0)) * 1024,
                'M' => ram_size = (try fmt.parseInt(usize, ms[0 .. ms.len - 1], 0)) * 1024 * 1024,
                'G' => ram_size = (try fmt.parseInt(usize, ms[0 .. ms.len - 1], 0)) * 1024 * 1024 * 1024,
                else => ram_size = try fmt.parseInt(usize, ms, 0),
            }
            // TODO: something wrong with memory size > 4G
            if (ram_size >= mmio.GAP_START) @panic("not support this large memory size right now!");
        } else {
            return usage();
        }
    }
    if (kernel_file_path == null) {
        return usage();
    }

    try kvm.open();
    defer kvm.close();

    // create vm
    try kvm.createVM(ram_size);
    defer kvm.destroyVM();

    // init vm
    try arch.init_vm(num_cores);

    if (blk_file_path) |path| {
        try virtio_blk.init(allocator, path, &cmdline);
        defer virtio_blk.deinit();
    }

    // load kernel into user memory
    try arch.load_kernel(kernel_file_path.?, cmdline, initrd_file_path);

    // forward stdin to guest
    try stdio.startCapture();
    defer stdio.stopCapture();

    // create vcpus and start them
    try vcpu.createAndStartCpus(num_cores);
}

fn nextArg(args: [][]const u8, idx: *usize) ?[]const u8 {
    if (idx.* >= args.len) return null;
    defer idx.* += 1;
    return args[idx.*];
}
