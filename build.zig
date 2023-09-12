const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zvm",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();

    const arch = if (target.cpu_arch) |arch| arch else builtin.cpu.arch;
    if (arch.isARM() or arch.isAARCH64()) {
        const libfdt = b.addStaticLibrary(.{
            .name = "libfdt",
            .target = target,
            .optimize = optimize,
        });
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
        libfdt.linkLibC();
        libfdt.addIncludePath(.{ .path = "src/libfdt"});

        exe.linkLibrary(libfdt);
        exe.addIncludePath(.{ .path = "src/libfdt"});
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
