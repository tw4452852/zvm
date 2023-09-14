var next: u8 = switch (@import("builtin").target.cpu.arch) {
    .x86_64 => 5,
    .aarch64 => 32,
    else => unreachable,
};

pub fn alloc() u8 {
    defer next += 1;
    return next;
}
