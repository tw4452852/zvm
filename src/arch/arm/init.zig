const std = @import("std");
const log = std.log;
const os = std.os;
const fs = std.fs;
const kvm = @import("root").kvm;
const c = @import("root").c;
const ioctl = os.linux.ioctl;
const mmio = @import("../../mmio.zig");
const libfdt = @cImport({
    @cInclude("libfdt.h");
});

var dts: [0x10000]u8 = undefined;

pub fn init_vm(num_cores: usize) !void {
    _ = libfdt.fdt_begin_node(&dts, "");
    _ = libfdt.fdt_property_cell(&dts, "#address-cells", 2);
    _ = libfdt.fdt_property_cell(&dts, "#size-cells", 2);

    try create_gic(num_cores);
}

fn create_gic(num_cores: usize) !void {
    create_gicv3(num_cores) catch try create_gicv2();
}

fn create_gicv2() !void {
    const vm = kvm.getVM();
    const gic_dist_size = 0x10000;
    const gic_cpu_size = 0x20000;

    var dev = c.kvm_create_device{
        .flags = 0,
        .type = c.KVM_DEV_TYPE_ARM_VGIC_V2,
        .fd = 0,
    };
    var ret = ioctl(vm, c.KVM_CREATE_DEVICE, @intFromPtr(&dev));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to create gicv2: {}", .{os.errno(ret)});
        return error.CREAT_GICV2;
    }
    errdefer os.close(@bitCast(dev.fd));

    const cpu = c.kvm_device_attr{
        .group = c.KVM_DEV_ARM_VGIC_GRP_ADDR,
        .attr = c.KVM_VGIC_V2_ADDR_TYPE_CPU,
        .addr = @intFromPtr(&mmio.alloc_space(gic_cpu_size)),
        .flags = 0,
    };
    ret = ioctl(vm, c.KVM_SET_DEVICE_ATTR, @intFromPtr(&cpu));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to create gicv2 cpu interface: {}", .{os.errno(ret)});
        return error.CREAT_GICV2;
    }

    const dist = c.kvm_device_attr{
        .group = c.KVM_DEV_ARM_VGIC_GRP_ADDR,
        .attr = c.KVM_VGIC_V2_ADDR_TYPE_DIST,
        .addr = @intFromPtr(&mmio.alloc_space(gic_dist_size)),
        .flags = 0,
    };
    ret = ioctl(vm, c.KVM_SET_DEVICE_ATTR, @intFromPtr(&dist));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to create gicv2 dist interface: {}", .{os.errno(ret)});
        return error.CREAT_GICV2;
    }

    _ = libfdt.fdt_begin_node(&dts, "intc");
    _ = libfdt.fdt_property(
        &dts,
        "compatible",
        "arm,cortex-a15-gic",
        "arm,cortex-a15-gic".len + 1,
    );
    _ = libfdt.fdt_property_cell(&dts, "#interrupt-cells", 3);
    _ = libfdt.fdt_property(&dts, "interrupt-controller", null, 0);
    _ = libfdt.fdt_end_node(&dts);
}

fn create_gicv3(num_cores: usize) !void {
    const vm = kvm.getVM();
    const gic_dist_size = 0x10000;
    const gic_redist_size = num_cores * 0x20000;

    var dev = c.kvm_create_device{
        .flags = 0,
        .type = c.KVM_DEV_TYPE_ARM_VGIC_V3,
        .fd = 0,
    };
    var ret = ioctl(vm, c.KVM_CREATE_DEVICE, @intFromPtr(&dev));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to create gicv3: {}", .{os.errno(ret)});
        return error.CREAT_GICV3;
    }
    errdefer os.close(@bitCast(dev.fd));

    const redist = c.kvm_device_attr{
        .group = c.KVM_DEV_ARM_VGIC_GRP_ADDR,
        .attr = c.KVM_VGIC_V3_ADDR_TYPE_REDIST,
        .addr = @intFromPtr(&mmio.alloc_space(gic_redist_size)),
        .flags = 0,
    };
    ret = ioctl(vm, c.KVM_SET_DEVICE_ATTR, @intFromPtr(&redist));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to create gicv3 redist interface: {}", .{os.errno(ret)});
        return error.CREAT_GICV3;
    }

    const dist = c.kvm_device_attr{
        .group = c.KVM_DEV_ARM_VGIC_GRP_ADDR,
        .attr = c.KVM_VGIC_V3_ADDR_TYPE_DIST,
        .addr = @intFromPtr(&mmio.alloc_space(gic_dist_size)),
        .flags = 0,
    };
    ret = ioctl(vm, c.KVM_SET_DEVICE_ATTR, @intFromPtr(&dist));
    if (os.errno(ret) != .SUCCESS) {
        log.err("failed to create gicv3 dist interface: {}", .{os.errno(ret)});
        return error.CREAT_GICV3;
    }
}

pub fn load_kernel(_: []const u8, _: []const u8, _: ?[]const u8) !void {}

pub fn init_vcpu(_: os.fd_t, _: usize) !void {}

pub fn dump_vcpu(_: os.fd_t) !void {}

pub fn record_ins(_: os.fd_t, _: ?*const c.kvm_debug_exit_arch) !void {}
