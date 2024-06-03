const std = @import("std");
const log = std.log;
const os = std.os;
const mem = std.mem;
const process = std.process;
const fmt = std.fmt;
const stdio = @import("stdio.zig");
const vcpu = @import("vcpu.zig");
const virtio_blk = @import("virtio_blk.zig");
const virtio_net = @import("virtio_net.zig");
const vfio = @import("vfio.zig");

pub const Arch = @import("arch/index.zig").Arch;
pub const pci = @import("pci.zig");
pub const kvm = @import("kvm.zig");
pub const mmio = @import("mmio.zig");
pub const io = @import("io.zig");
pub const portio = @import("portio.zig");
pub const irq = @import("irq.zig");
pub const virtio_mmio = @import("virtio_mmio.zig");
pub const Cmdline = std.BoundedArray(u8, 512);
pub const c = @cImport({
    @cInclude("linux/kvm.h");
    @cInclude("linux/kvm_para.h");
    @cInclude("sys/mman.h");
    @cInclude("linux/if_tun.h");
    @cInclude("linux/if.h");
    @cInclude("linux/sockios.h");
    @cInclude("linux/vfio.h");
});

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
        \\ -n # enable virtio-net
        \\ -p [path to pci device in sysfs, e.g. /sys/bus/pci/0000:00:01.0/]
    , .{});
    return error.USAGE;
}

fn interrupt_handler(_: c_int) callconv(.C) void {
    log.info("interrupted, exiting...", .{});
    stdio.stopCapture();
    virtio_net.deinit();
    vfio.deinit();

    log.info("done", .{});
    std.posix.exit(0);
}

fn setup_ctrl_c() !void {
    const act = std.posix.Sigaction{
        .handler = .{ .handler = interrupt_handler },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };
    try std.posix.sigaction(std.posix.SIG.INT, &act, null);
}

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);
    var arg_idx: usize = 1; // skip exe name

    var kernel_file_path: ?[]const u8 = null;
    var initrd_file_path: ?[]const u8 = null;
    var blk_file_path: ?[]const u8 = null;
    var cmdline = try Cmdline.fromSlice("console=ttyS0 panic=1");
    var ram_size: usize = 0x100_00000; // 256M
    var enable_virtio_net = false;
    var passthrough_pci_devs = std.ArrayList([]const u8).init(allocator);

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
            const input = nextArg(args, &arg_idx) orelse {
                return usage();
            };
            try cmdline.resize(0);
            try cmdline.appendSlice(input);
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
        } else if (mem.eql(u8, arg, "-n")) {
            enable_virtio_net = true;
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
        } else if (mem.eql(u8, arg, "-p")) {
            const path = nextArg(args, &arg_idx) orelse {
                return usage();
            };
            try passthrough_pci_devs.append(path);
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
    try Arch.init_vm(num_cores);

    try pci.init();
    defer pci.deinit();

    if (blk_file_path) |path| {
        try virtio_blk.init(allocator, path);
    }
    defer if (blk_file_path != null) virtio_blk.deinit();

    if (enable_virtio_net) try virtio_net.init(allocator);
    defer if (enable_virtio_net) virtio_net.deinit();

    if (passthrough_pci_devs.items.len > 0) {
        try vfio.init(allocator, passthrough_pci_devs.items);
    }
    defer if (passthrough_pci_devs.items.len > 0) vfio.deinit();

    // load kernel into user memory
    try Arch.load_kernel(kernel_file_path.?, &cmdline, initrd_file_path);

    // forward stdin to guest
    try stdio.startCapture();
    defer stdio.stopCapture();

    try setup_ctrl_c();

    // create vcpus and start them
    try vcpu.createAndStartCpus(num_cores);
}

fn nextArg(args: [][]const u8, idx: *usize) ?[]const u8 {
    if (idx.* >= args.len) return null;
    defer idx.* += 1;
    return args[idx.*];
}
