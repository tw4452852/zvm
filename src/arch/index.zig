pub const Arch = switch (@import("builtin").target.cpu.arch) {
    .x86_64 => @import("x86/init.zig"),
    .aarch64 => @import("arm/init.zig"),
    else => unreachable,
};
