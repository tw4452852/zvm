const arch = @import("builtin").target.cpu.arch;

pub const init_vm = switch (arch) {
    .x86_64 => @import("x86/init.zig").init_vm,
    else => unreachable,
};

pub const load_kernel = switch (arch) {
    .x86_64 => @import("x86/init.zig").load_kernel,
    else => unreachable,
};

pub const init_vcpu = switch (arch) {
    .x86_64 => @import("x86/init.zig").init_vcpu,
    else => unreachable,
};

pub const dump_vcpu = switch (arch) {
    .x86_64 => @import("x86/init.zig").dump_vcpu,
    else => unreachable,
};

pub const record_ins = switch (arch) {
    .x86_64 => @import("x86/init.zig").record_ins,
    else => unreachable,
};
