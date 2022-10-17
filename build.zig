const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zvm", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();

    const arch = if (target.cpu_arch) |arch| arch else builtin.cpu.arch;
    if (arch.isARM() or arch.isAARCH64()) {
        const libfdt = b.addStaticLibrary("libfdt", null);
        const libfdtSources = [_][]const u8{
            "src/libfdt/fdt.c",
            "src/libfdt/fdt_addresses.c",
            "src/libfdt/fdt_check.c",
            "src/libfdt/fdt_empty_tree.c",
            "src/libfdt/fdt_overlay.c",
            "src/libfdt/fdt_ro.c",
            "src/libfdt/fdt_rw.c",
            "src/libfdt/fdt_strerror.c",
            "src/libfdt/fdt_sw.c",
            "src/libfdt/fdt_wip.c",
        };
        const libfdtFlags = [_][]const u8{};
        libfdt.addCSourceFiles(&libfdtSources, &libfdtFlags);
        libfdt.setTarget(target);
        libfdt.setBuildMode(mode);
        libfdt.linkLibC();
        libfdt.addIncludePath("src/libfdt");

        exe.linkLibrary(libfdt);
        exe.addIncludePath("src/libfdt");
    }

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
