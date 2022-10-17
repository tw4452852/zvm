pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
pub const __s8 = i8;
pub const __u8 = u8;
pub const __s16 = c_short;
pub const __u16 = c_ushort;
pub const __s32 = c_int;
pub const __u32 = c_uint;
pub const __s64 = c_longlong;
pub const __u64 = c_ulonglong;
pub const __kernel_fd_set = extern struct {
    fds_bits: [16]c_ulong,
};
pub const __kernel_sighandler_t = ?*const fn (c_int) callconv(.C) void;
pub const __kernel_key_t = c_int;
pub const __kernel_mqd_t = c_int;
pub const __kernel_old_uid_t = c_ushort;
pub const __kernel_old_gid_t = c_ushort;
pub const __kernel_old_dev_t = c_ulong;
pub const __kernel_long_t = c_long;
pub const __kernel_ulong_t = c_ulong;
pub const __kernel_ino_t = __kernel_ulong_t;
pub const __kernel_mode_t = c_uint;
pub const __kernel_pid_t = c_int;
pub const __kernel_ipc_pid_t = c_int;
pub const __kernel_uid_t = c_uint;
pub const __kernel_gid_t = c_uint;
pub const __kernel_suseconds_t = __kernel_long_t;
pub const __kernel_daddr_t = c_int;
pub const __kernel_uid32_t = c_uint;
pub const __kernel_gid32_t = c_uint;
pub const __kernel_size_t = __kernel_ulong_t;
pub const __kernel_ssize_t = __kernel_long_t;
pub const __kernel_ptrdiff_t = __kernel_long_t;
pub const __kernel_fsid_t = extern struct {
    val: [2]c_int,
};
pub const __kernel_off_t = __kernel_long_t;
pub const __kernel_loff_t = c_longlong;
pub const __kernel_old_time_t = __kernel_long_t;
pub const __kernel_time_t = __kernel_long_t;
pub const __kernel_time64_t = c_longlong;
pub const __kernel_clock_t = __kernel_long_t;
pub const __kernel_timer_t = c_int;
pub const __kernel_clockid_t = c_int;
pub const __kernel_caddr_t = [*c]u8;
pub const __kernel_uid16_t = c_ushort;
pub const __kernel_gid16_t = c_ushort;
pub const __le16 = __u16;
pub const __be16 = __u16;
pub const __le32 = __u32;
pub const __be32 = __u32;
pub const __le64 = __u64;
pub const __be64 = __u64;
pub const __sum16 = __u16;
pub const __wsum = __u32;
pub const __poll_t = c_uint;
pub const struct_screen_info = extern struct {
    orig_x: __u8 align(1),
    orig_y: __u8 align(1),
    ext_mem_k: __u16 align(1),
    orig_video_page: __u16 align(1),
    orig_video_mode: __u8 align(1),
    orig_video_cols: __u8 align(1),
    flags: __u8 align(1),
    unused2: __u8 align(1),
    orig_video_ega_bx: __u16 align(1),
    unused3: __u16 align(1),
    orig_video_lines: __u8 align(1),
    orig_video_isVGA: __u8 align(1),
    orig_video_points: __u16 align(1),
    lfb_width: __u16 align(1),
    lfb_height: __u16 align(1),
    lfb_depth: __u16 align(1),
    lfb_base: __u32 align(1),
    lfb_size: __u32 align(1),
    cl_magic: __u16 align(1),
    cl_offset: __u16 align(1),
    lfb_linelength: __u16 align(1),
    red_size: __u8 align(1),
    red_pos: __u8 align(1),
    green_size: __u8 align(1),
    green_pos: __u8 align(1),
    blue_size: __u8 align(1),
    blue_pos: __u8 align(1),
    rsvd_size: __u8 align(1),
    rsvd_pos: __u8 align(1),
    vesapm_seg: __u16 align(1),
    vesapm_off: __u16 align(1),
    pages: __u16 align(1),
    vesa_attributes: __u16 align(1),
    capabilities: __u32 align(1),
    ext_lfb_base: __u32 align(1),
    _reserved: [2]__u8 align(1),
};
pub const apm_event_t = c_ushort;
pub const apm_eventinfo_t = c_ushort;
pub const struct_apm_bios_info = extern struct {
    version: __u16,
    cseg: __u16,
    offset: __u32,
    cseg_16: __u16,
    dseg: __u16,
    flags: __u16,
    cseg_len: __u16,
    cseg_16_len: __u16,
    dseg_len: __u16,
};
const struct_unnamed_2 = extern struct {
    base_address: __u16 align(1),
    reserved1: __u16 align(1),
    reserved2: __u32 align(1),
};
const struct_unnamed_3 = extern struct {
    bus: __u8 align(1),
    slot: __u8 align(1),
    function: __u8 align(1),
    channel: __u8 align(1),
    reserved: __u32 align(1),
};
const struct_unnamed_4 = extern struct {
    reserved: __u64 align(1),
};
const struct_unnamed_5 = extern struct {
    reserved: __u64 align(1),
};
const struct_unnamed_6 = extern struct {
    reserved: __u64 align(1),
};
const struct_unnamed_7 = extern struct {
    reserved: __u64 align(1),
};
const union_unnamed_1 = extern union {
    isa: struct_unnamed_2,
    pci: struct_unnamed_3,
    ibnd: struct_unnamed_4,
    xprs: struct_unnamed_5,
    htpt: struct_unnamed_6,
    unknown: struct_unnamed_7,
};
const struct_unnamed_9 = extern struct {
    device: __u8 align(1),
    reserved1: __u8 align(1),
    reserved2: __u16 align(1),
    reserved3: __u32 align(1),
    reserved4: __u64 align(1),
};
const struct_unnamed_10 = extern struct {
    device: __u8 align(1),
    lun: __u8 align(1),
    reserved1: __u8 align(1),
    reserved2: __u8 align(1),
    reserved3: __u32 align(1),
    reserved4: __u64 align(1),
};
const struct_unnamed_11 = extern struct {
    id: __u16 align(1),
    lun: __u64 align(1),
    reserved1: __u16 align(1),
    reserved2: __u32 align(1),
};
const struct_unnamed_12 = extern struct {
    serial_number: __u64 align(1),
    reserved: __u64 align(1),
};
const struct_unnamed_13 = extern struct {
    eui: __u64 align(1),
    reserved: __u64 align(1),
};
const struct_unnamed_14 = extern struct {
    wwid: __u64 align(1),
    lun: __u64 align(1),
};
const struct_unnamed_15 = extern struct {
    identity_tag: __u64 align(1),
    reserved: __u64 align(1),
};
const struct_unnamed_16 = extern struct {
    array_number: __u32 align(1),
    reserved1: __u32 align(1),
    reserved2: __u64 align(1),
};
const struct_unnamed_17 = extern struct {
    device: __u8 align(1),
    reserved1: __u8 align(1),
    reserved2: __u16 align(1),
    reserved3: __u32 align(1),
    reserved4: __u64 align(1),
};
const struct_unnamed_18 = extern struct {
    reserved1: __u64 align(1),
    reserved2: __u64 align(1),
};
const union_unnamed_8 = extern union {
    ata: struct_unnamed_9,
    atapi: struct_unnamed_10,
    scsi: struct_unnamed_11,
    usb: struct_unnamed_12,
    i1394: struct_unnamed_13,
    fibre: struct_unnamed_14,
    i2o: struct_unnamed_15,
    raid: struct_unnamed_16,
    sata: struct_unnamed_17,
    unknown: struct_unnamed_18,
};
pub const struct_edd_device_params = extern struct {
    length: __u16 align(1),
    info_flags: __u16 align(1),
    num_default_cylinders: __u32 align(1),
    num_default_heads: __u32 align(1),
    sectors_per_track: __u32 align(1),
    number_of_sectors: __u64 align(1),
    bytes_per_sector: __u16 align(1),
    dpte_ptr: __u32 align(1),
    key: __u16 align(1),
    device_path_info_length: __u8 align(1),
    reserved2: __u8 align(1),
    reserved3: __u16 align(1),
    host_bus_type: [4]__u8 align(1),
    interface_type: [8]__u8 align(1),
    interface_path: union_unnamed_1 align(1),
    device_path: union_unnamed_8 align(1),
    reserved4: __u8 align(1),
    checksum: __u8 align(1),
};
pub const struct_edd_info = extern struct {
    device: __u8 align(1),
    version: __u8 align(1),
    interface_support: __u16 align(1),
    legacy_max_cylinder: __u16 align(1),
    legacy_max_head: __u8 align(1),
    legacy_sectors_per_track: __u8 align(1),
    params: struct_edd_device_params align(1),
};
pub const struct_edd = extern struct {
    mbr_signature: [16]c_uint,
    edd_info: [6]struct_edd_info,
    mbr_signature_nr: u8,
    edd_info_nr: u8,
};
pub const struct_ist_info = extern struct {
    signature: __u32,
    command: __u32,
    event: __u32,
    perf_level: __u32,
};
pub const struct_edid_info = extern struct {
    dummy: [128]u8,
};
pub const struct_setup_data = extern struct {
    next: __u64 align(8),
    type: __u32,
    len: __u32,
    pub fn data(self: anytype) @import("std").zig.c_translation.FlexibleArrayType(@TypeOf(self), __u8) {
        const Intermediate = @import("std").zig.c_translation.FlexibleArrayType(@TypeOf(self), u8);
        const ReturnType = @import("std").zig.c_translation.FlexibleArrayType(@TypeOf(self), __u8);
        return @ptrCast(ReturnType, @alignCast(@alignOf(__u8), @ptrCast(Intermediate, self) + 16));
    }
};
pub const struct_setup_indirect = extern struct {
    type: __u32,
    reserved: __u32,
    len: __u64,
    addr: __u64,
};
pub const struct_setup_header = extern struct {
    setup_sects: __u8 align(1),
    root_flags: __u16 align(1),
    syssize: __u32 align(1),
    ram_size: __u16 align(1),
    vid_mode: __u16 align(1),
    root_dev: __u16 align(1),
    boot_flag: __u16 align(1),
    jump: __u16 align(1),
    header: __u32 align(1),
    version: __u16 align(1),
    realmode_swtch: __u32 align(1),
    start_sys_seg: __u16 align(1),
    kernel_version: __u16 align(1),
    type_of_loader: __u8 align(1),
    loadflags: __u8 align(1),
    setup_move_size: __u16 align(1),
    code32_start: __u32 align(1),
    ramdisk_image: __u32 align(1),
    ramdisk_size: __u32 align(1),
    bootsect_kludge: __u32 align(1),
    heap_end_ptr: __u16 align(1),
    ext_loader_ver: __u8 align(1),
    ext_loader_type: __u8 align(1),
    cmd_line_ptr: __u32 align(1),
    initrd_addr_max: __u32 align(1),
    kernel_alignment: __u32 align(1),
    relocatable_kernel: __u8 align(1),
    min_alignment: __u8 align(1),
    xloadflags: __u16 align(1),
    cmdline_size: __u32 align(1),
    hardware_subarch: __u32 align(1),
    hardware_subarch_data: __u64 align(1),
    payload_offset: __u32 align(1),
    payload_length: __u32 align(1),
    setup_data: __u64 align(1),
    pref_address: __u64 align(1),
    init_size: __u32 align(1),
    handover_offset: __u32 align(1),
    kernel_info_offset: __u32 align(1),
};
pub const struct_sys_desc_table = extern struct {
    length: __u16,
    table: [14]__u8,
};
pub const struct_olpc_ofw_header = extern struct {
    ofw_magic: __u32 align(1),
    ofw_version: __u32 align(1),
    cif_handler: __u32 align(1),
    irq_desc_table: __u32 align(1),
};
pub const struct_efi_info = extern struct {
    efi_loader_signature: __u32,
    efi_systab: __u32,
    efi_memdesc_size: __u32,
    efi_memdesc_version: __u32,
    efi_memmap: __u32,
    efi_memmap_size: __u32,
    efi_systab_hi: __u32,
    efi_memmap_hi: __u32,
};
pub const struct_boot_e820_entry = extern struct {
    addr: __u64 align(1),
    size: __u64 align(1),
    type: __u32 align(1),
};
const struct_unnamed_19 = extern struct {
    version: __u16 align(1),
    compatible_version: __u16 align(1),
};
const struct_unnamed_20 = extern struct {
    pm_timer_address: __u16 align(1),
    num_cpus: __u16 align(1),
    pci_mmconfig_base: __u64 align(1),
    tsc_khz: __u32 align(1),
    apic_khz: __u32 align(1),
    standard_ioapic: __u8 align(1),
    cpu_ids: [255]__u8 align(1),
};
const struct_unnamed_21 = extern struct {
    flags: __u32 align(1),
};
pub const struct_jailhouse_setup_data = extern struct {
    hdr: struct_unnamed_19 align(1),
    v1: struct_unnamed_20 align(1),
    v2: struct_unnamed_21 align(1),
};
pub const struct_boot_params = extern struct {
    screen_info: struct_screen_info align(1),
    apm_bios_info: struct_apm_bios_info align(1),
    _pad2: [4]__u8 align(1),
    tboot_addr: __u64 align(1),
    ist_info: struct_ist_info align(1),
    acpi_rsdp_addr: __u64 align(1),
    _pad3: [8]__u8 align(1),
    hd0_info: [16]__u8 align(1),
    hd1_info: [16]__u8 align(1),
    sys_desc_table: struct_sys_desc_table align(1),
    olpc_ofw_header: struct_olpc_ofw_header align(1),
    ext_ramdisk_image: __u32 align(1),
    ext_ramdisk_size: __u32 align(1),
    ext_cmd_line_ptr: __u32 align(1),
    _pad4: [116]__u8 align(1),
    edid_info: struct_edid_info align(1),
    efi_info: struct_efi_info align(1),
    alt_mem_k: __u32 align(1),
    scratch: __u32 align(1),
    e820_entries: __u8 align(1),
    eddbuf_entries: __u8 align(1),
    edd_mbr_sig_buf_entries: __u8 align(1),
    kbd_status: __u8 align(1),
    secure_boot: __u8 align(1),
    _pad5: [2]__u8 align(1),
    sentinel: __u8 align(1),
    _pad6: [1]__u8 align(1),
    hdr: struct_setup_header align(1),
    _pad7: [36]__u8 align(1),
    edd_mbr_sig_buffer: [16]__u32 align(1),
    e820_table: [128]struct_boot_e820_entry align(1),
    _pad8: [48]__u8 align(1),
    eddbuf: [6]struct_edd_info align(1),
    _pad9: [276]__u8 align(1),
};
pub const X86_SUBARCH_PC: c_int = 0;
pub const X86_SUBARCH_LGUEST: c_int = 1;
pub const X86_SUBARCH_XEN: c_int = 2;
pub const X86_SUBARCH_INTEL_MID: c_int = 3;
pub const X86_SUBARCH_CE4100: c_int = 4;
pub const X86_NR_SUBARCHS: c_int = 5;
pub const enum_x86_hardware_subarch = c_uint;
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`"); // (no file):80:9
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`"); // (no file):86:9
pub const __FLT16_DENORM_MIN__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):109:9
pub const __FLT16_EPSILON__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):113:9
pub const __FLT16_MAX__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):119:9
pub const __FLT16_MIN__ = @compileError("unable to translate C expr: unexpected token 'IntegerLiteral'"); // (no file):122:9
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`"); // (no file):183:9
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`"); // (no file):205:9
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`"); // (no file):213:9
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):343:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // (no file):344:9
pub const __always_inline = @compileError("unable to translate macro: undefined identifier `__inline__`"); // /usr/include/linux/stddef.h:5:9
pub const __aligned_u64 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/linux/types.h:43:9
pub const __aligned_be64 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/linux/types.h:44:9
pub const __aligned_le64 = @compileError("unable to translate macro: undefined identifier `__attribute__`"); // /usr/include/linux/types.h:45:9
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 15);
pub const __clang_minor__ = @as(c_int, 0);
pub const __clang_patchlevel__ = @as(c_int, 0);
pub const __clang_version__ = "15.0.0 (git@github.com:ziglang/zig-bootstrap.git 9be8396b715b10f64d8a94b2d0d9acb77126d8ca)";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 15.0.0 (git@github.com:ziglang/zig-bootstrap.git 9be8396b715b10f64d8a94b2d0d9acb77126d8ca)";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-32";
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = @as(c_int, 128);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_FMTd__ = "ld";
pub const __INTMAX_FMTi__ = "li";
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_FMTo__ = "lo";
pub const __UINTMAX_FMTu__ = "lu";
pub const __UINTMAX_FMTx__ = "lx";
pub const __UINTMAX_FMTX__ = "lX";
pub const __PTRDIFF_TYPE__ = c_long;
pub const __PTRDIFF_FMTd__ = "ld";
pub const __PTRDIFF_FMTi__ = "li";
pub const __INTPTR_TYPE__ = c_long;
pub const __INTPTR_FMTd__ = "ld";
pub const __INTPTR_FMTi__ = "li";
pub const __SIZE_TYPE__ = c_ulong;
pub const __SIZE_FMTo__ = "lo";
pub const __SIZE_FMTu__ = "lu";
pub const __SIZE_FMTx__ = "lx";
pub const __SIZE_FMTX__ = "lX";
pub const __WCHAR_TYPE__ = c_int;
pub const __WINT_TYPE__ = c_uint;
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __UINTPTR_FMTo__ = "lo";
pub const __UINTPTR_FMTu__ = "lu";
pub const __UINTPTR_FMTx__ = "lx";
pub const __UINTPTR_FMTX__ = "lX";
pub const __FLT16_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT16_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = 4.9406564584124654e-324;
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = 2.2204460492503131e-16;
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = 1.7976931348623157e+308;
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = 2.2250738585072014e-308;
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub const __INT64_TYPE__ = c_long;
pub const __INT64_FMTd__ = "ld";
pub const __INT64_FMTi__ = "li";
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub const __UINT16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulong;
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __INT64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_long;
pub const __INT_LEAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "ld";
pub const __INT_LEAST64_FMTi__ = "li";
pub const __UINT_LEAST64_TYPE__ = c_ulong;
pub const __UINT_LEAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_LEAST64_FMTo__ = "lo";
pub const __UINT_LEAST64_FMTu__ = "lu";
pub const __UINT_LEAST64_FMTx__ = "lx";
pub const __UINT_LEAST64_FMTX__ = "lX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_long;
pub const __INT_FAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "ld";
pub const __INT_FAST64_FMTi__ = "li";
pub const __UINT_FAST64_TYPE__ = c_ulong;
pub const __UINT_FAST64_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINT_FAST64_FMTo__ = "lo";
pub const __UINT_FAST64_FMTu__ = "lu";
pub const __UINT_FAST64_FMTx__ = "lx";
pub const __UINT_FAST64_FMTX__ = "lX";
pub const __USER_LABEL_PREFIX__ = "";
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __NO_INLINE__ = @as(c_int, 1);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __PIE__ = @as(c_int, 2);
pub const __pie__ = @as(c_int, 2);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __corei7 = @as(c_int, 1);
pub const __corei7__ = @as(c_int, 1);
pub const __tune_corei7__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __RTM__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __INVPCID__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const linux = @as(c_int, 1);
pub const __linux = @as(c_int, 1);
pub const __linux__ = @as(c_int, 1);
pub const __ELF__ = @as(c_int, 1);
pub const __gnu_linux__ = @as(c_int, 1);
pub const __FLOAT128__ = @as(c_int, 1);
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const _DEBUG = @as(c_int, 1);
pub const __GCC_HAVE_DWARF2_CFI_ASM = @as(c_int, 1);
pub const _ASM_X86_BOOTPARAM_H = "";
pub const SETUP_NONE = @as(c_int, 0);
pub const SETUP_E820_EXT = @as(c_int, 1);
pub const SETUP_DTB = @as(c_int, 2);
pub const SETUP_PCI = @as(c_int, 3);
pub const SETUP_EFI = @as(c_int, 4);
pub const SETUP_APPLE_PROPERTIES = @as(c_int, 5);
pub const SETUP_JAILHOUSE = @as(c_int, 6);
pub const SETUP_INDIRECT = @as(c_int, 1) << @as(c_int, 31);
pub const SETUP_TYPE_MAX = SETUP_INDIRECT | SETUP_JAILHOUSE;
pub const RAMDISK_IMAGE_START_MASK = @as(c_int, 0x07FF);
pub const RAMDISK_PROMPT_FLAG = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8000, .hexadecimal);
pub const RAMDISK_LOAD_FLAG = @as(c_int, 0x4000);
pub const LOADED_HIGH = @as(c_int, 1) << @as(c_int, 0);
pub const KASLR_FLAG = @as(c_int, 1) << @as(c_int, 1);
pub const QUIET_FLAG = @as(c_int, 1) << @as(c_int, 5);
pub const KEEP_SEGMENTS = @as(c_int, 1) << @as(c_int, 6);
pub const CAN_USE_HEAP = @as(c_int, 1) << @as(c_int, 7);
pub const XLF_KERNEL_64 = @as(c_int, 1) << @as(c_int, 0);
pub const XLF_CAN_BE_LOADED_ABOVE_4G = @as(c_int, 1) << @as(c_int, 1);
pub const XLF_EFI_HANDOVER_32 = @as(c_int, 1) << @as(c_int, 2);
pub const XLF_EFI_HANDOVER_64 = @as(c_int, 1) << @as(c_int, 3);
pub const XLF_EFI_KEXEC = @as(c_int, 1) << @as(c_int, 4);
pub const XLF_5LEVEL = @as(c_int, 1) << @as(c_int, 5);
pub const XLF_5LEVEL_ENABLED = @as(c_int, 1) << @as(c_int, 6);
pub const _LINUX_TYPES_H = "";
pub const _ASM_GENERIC_TYPES_H = "";
pub const _ASM_GENERIC_INT_LL64_H = "";
pub const __ASM_X86_BITSPERLONG_H = "";
pub const __BITS_PER_LONG = @as(c_int, 64);
pub const __ASM_GENERIC_BITS_PER_LONG = "";
pub const _LINUX_POSIX_TYPES_H = "";
pub const __FD_SETSIZE = @as(c_int, 1024);
pub const _ASM_X86_POSIX_TYPES_64_H = "";
pub const __ASM_GENERIC_POSIX_TYPES_H = "";
pub const __bitwise__ = "";
pub const __bitwise = __bitwise__;
pub const _SCREEN_INFO_H = "";
pub const VIDEO_TYPE_MDA = @as(c_int, 0x10);
pub const VIDEO_TYPE_CGA = @as(c_int, 0x11);
pub const VIDEO_TYPE_EGAM = @as(c_int, 0x20);
pub const VIDEO_TYPE_EGAC = @as(c_int, 0x21);
pub const VIDEO_TYPE_VGAC = @as(c_int, 0x22);
pub const VIDEO_TYPE_VLFB = @as(c_int, 0x23);
pub const VIDEO_TYPE_PICA_S3 = @as(c_int, 0x30);
pub const VIDEO_TYPE_MIPS_G364 = @as(c_int, 0x31);
pub const VIDEO_TYPE_SGI = @as(c_int, 0x33);
pub const VIDEO_TYPE_TGAC = @as(c_int, 0x40);
pub const VIDEO_TYPE_SUN = @as(c_int, 0x50);
pub const VIDEO_TYPE_SUNPCI = @as(c_int, 0x51);
pub const VIDEO_TYPE_PMAC = @as(c_int, 0x60);
pub const VIDEO_TYPE_EFI = @as(c_int, 0x70);
pub const VIDEO_FLAGS_NOCURSOR = @as(c_int, 1) << @as(c_int, 0);
pub const VIDEO_CAPABILITY_SKIP_QUIRKS = @as(c_int, 1) << @as(c_int, 0);
pub const VIDEO_CAPABILITY_64BIT_BASE = @as(c_int, 1) << @as(c_int, 1);
pub const _LINUX_APM_H = "";
pub const APM_STATE_READY = @as(c_int, 0x0000);
pub const APM_STATE_STANDBY = @as(c_int, 0x0001);
pub const APM_STATE_SUSPEND = @as(c_int, 0x0002);
pub const APM_STATE_OFF = @as(c_int, 0x0003);
pub const APM_STATE_BUSY = @as(c_int, 0x0004);
pub const APM_STATE_REJECT = @as(c_int, 0x0005);
pub const APM_STATE_OEM_SYS = @as(c_int, 0x0020);
pub const APM_STATE_OEM_DEV = @as(c_int, 0x0040);
pub const APM_STATE_DISABLE = @as(c_int, 0x0000);
pub const APM_STATE_ENABLE = @as(c_int, 0x0001);
pub const APM_STATE_DISENGAGE = @as(c_int, 0x0000);
pub const APM_STATE_ENGAGE = @as(c_int, 0x0001);
pub const APM_SYS_STANDBY = @as(c_int, 0x0001);
pub const APM_SYS_SUSPEND = @as(c_int, 0x0002);
pub const APM_NORMAL_RESUME = @as(c_int, 0x0003);
pub const APM_CRITICAL_RESUME = @as(c_int, 0x0004);
pub const APM_LOW_BATTERY = @as(c_int, 0x0005);
pub const APM_POWER_STATUS_CHANGE = @as(c_int, 0x0006);
pub const APM_UPDATE_TIME = @as(c_int, 0x0007);
pub const APM_CRITICAL_SUSPEND = @as(c_int, 0x0008);
pub const APM_USER_STANDBY = @as(c_int, 0x0009);
pub const APM_USER_SUSPEND = @as(c_int, 0x000a);
pub const APM_STANDBY_RESUME = @as(c_int, 0x000b);
pub const APM_CAPABILITY_CHANGE = @as(c_int, 0x000c);
pub const APM_USER_HIBERNATION = @as(c_int, 0x000d);
pub const APM_HIBERNATION_RESUME = @as(c_int, 0x000e);
pub const APM_SUCCESS = @as(c_int, 0x00);
pub const APM_DISABLED = @as(c_int, 0x01);
pub const APM_CONNECTED = @as(c_int, 0x02);
pub const APM_NOT_CONNECTED = @as(c_int, 0x03);
pub const APM_16_CONNECTED = @as(c_int, 0x05);
pub const APM_16_UNSUPPORTED = @as(c_int, 0x06);
pub const APM_32_CONNECTED = @as(c_int, 0x07);
pub const APM_32_UNSUPPORTED = @as(c_int, 0x08);
pub const APM_BAD_DEVICE = @as(c_int, 0x09);
pub const APM_BAD_PARAM = @as(c_int, 0x0a);
pub const APM_NOT_ENGAGED = @as(c_int, 0x0b);
pub const APM_BAD_FUNCTION = @as(c_int, 0x0c);
pub const APM_RESUME_DISABLED = @as(c_int, 0x0d);
pub const APM_NO_ERROR = @as(c_int, 0x53);
pub const APM_BAD_STATE = @as(c_int, 0x60);
pub const APM_NO_EVENTS = @as(c_int, 0x80);
pub const APM_NOT_PRESENT = @as(c_int, 0x86);
pub const APM_DEVICE_BIOS = @as(c_int, 0x0000);
pub const APM_DEVICE_ALL = @as(c_int, 0x0001);
pub const APM_DEVICE_DISPLAY = @as(c_int, 0x0100);
pub const APM_DEVICE_STORAGE = @as(c_int, 0x0200);
pub const APM_DEVICE_PARALLEL = @as(c_int, 0x0300);
pub const APM_DEVICE_SERIAL = @as(c_int, 0x0400);
pub const APM_DEVICE_NETWORK = @as(c_int, 0x0500);
pub const APM_DEVICE_PCMCIA = @as(c_int, 0x0600);
pub const APM_DEVICE_BATTERY = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0x8000, .hexadecimal);
pub const APM_DEVICE_OEM = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xe000, .hexadecimal);
pub const APM_DEVICE_OLD_ALL = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xffff, .hexadecimal);
pub const APM_DEVICE_CLASS = @as(c_int, 0x00ff);
pub const APM_DEVICE_MASK = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xff00, .hexadecimal);
pub const APM_MAX_BATTERIES = @as(c_int, 2);
pub const APM_CAP_GLOBAL_STANDBY = @as(c_int, 0x0001);
pub const APM_CAP_GLOBAL_SUSPEND = @as(c_int, 0x0002);
pub const APM_CAP_RESUME_STANDBY_TIMER = @as(c_int, 0x0004);
pub const APM_CAP_RESUME_SUSPEND_TIMER = @as(c_int, 0x0008);
pub const APM_CAP_RESUME_STANDBY_RING = @as(c_int, 0x0010);
pub const APM_CAP_RESUME_SUSPEND_RING = @as(c_int, 0x0020);
pub const APM_CAP_RESUME_STANDBY_PCMCIA = @as(c_int, 0x0040);
pub const APM_CAP_RESUME_SUSPEND_PCMCIA = @as(c_int, 0x0080);
pub const _LINUX_IOCTL_H = "";
pub const _ASM_GENERIC_IOCTL_H = "";
pub const _IOC_NRBITS = @as(c_int, 8);
pub const _IOC_TYPEBITS = @as(c_int, 8);
pub const _IOC_SIZEBITS = @as(c_int, 14);
pub const _IOC_DIRBITS = @as(c_int, 2);
pub const _IOC_NRMASK = (@as(c_int, 1) << _IOC_NRBITS) - @as(c_int, 1);
pub const _IOC_TYPEMASK = (@as(c_int, 1) << _IOC_TYPEBITS) - @as(c_int, 1);
pub const _IOC_SIZEMASK = (@as(c_int, 1) << _IOC_SIZEBITS) - @as(c_int, 1);
pub const _IOC_DIRMASK = (@as(c_int, 1) << _IOC_DIRBITS) - @as(c_int, 1);
pub const _IOC_NRSHIFT = @as(c_int, 0);
pub const _IOC_TYPESHIFT = _IOC_NRSHIFT + _IOC_NRBITS;
pub const _IOC_SIZESHIFT = _IOC_TYPESHIFT + _IOC_TYPEBITS;
pub const _IOC_DIRSHIFT = _IOC_SIZESHIFT + _IOC_SIZEBITS;
pub const _IOC_NONE = @as(c_uint, 0);
pub const _IOC_WRITE = @as(c_uint, 1);
pub const _IOC_READ = @as(c_uint, 2);
pub inline fn _IOC(dir: anytype, @"type": anytype, nr: anytype, size: anytype) @TypeOf((((dir << _IOC_DIRSHIFT) | (@"type" << _IOC_TYPESHIFT)) | (nr << _IOC_NRSHIFT)) | (size << _IOC_SIZESHIFT)) {
    return (((dir << _IOC_DIRSHIFT) | (@"type" << _IOC_TYPESHIFT)) | (nr << _IOC_NRSHIFT)) | (size << _IOC_SIZESHIFT);
}
pub inline fn _IOC_TYPECHECK(t: anytype) @TypeOf(@import("std").zig.c_translation.sizeof(t)) {
    _ = @TypeOf(t);
    return @import("std").zig.c_translation.sizeof(t);
}
pub inline fn _IO(@"type": anytype, nr: anytype) @TypeOf(_IOC(_IOC_NONE, @"type", nr, @as(c_int, 0))) {
    return _IOC(_IOC_NONE, @"type", nr, @as(c_int, 0));
}
pub inline fn _IOR(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_READ, @"type", nr, _IOC_TYPECHECK(size))) {
    return _IOC(_IOC_READ, @"type", nr, _IOC_TYPECHECK(size));
}
pub inline fn _IOW(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_WRITE, @"type", nr, _IOC_TYPECHECK(size))) {
    return _IOC(_IOC_WRITE, @"type", nr, _IOC_TYPECHECK(size));
}
pub inline fn _IOWR(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_READ | _IOC_WRITE, @"type", nr, _IOC_TYPECHECK(size))) {
    return _IOC(_IOC_READ | _IOC_WRITE, @"type", nr, _IOC_TYPECHECK(size));
}
pub inline fn _IOR_BAD(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_READ, @"type", nr, @import("std").zig.c_translation.sizeof(size))) {
    _ = @TypeOf(size);
    return _IOC(_IOC_READ, @"type", nr, @import("std").zig.c_translation.sizeof(size));
}
pub inline fn _IOW_BAD(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_WRITE, @"type", nr, @import("std").zig.c_translation.sizeof(size))) {
    _ = @TypeOf(size);
    return _IOC(_IOC_WRITE, @"type", nr, @import("std").zig.c_translation.sizeof(size));
}
pub inline fn _IOWR_BAD(@"type": anytype, nr: anytype, size: anytype) @TypeOf(_IOC(_IOC_READ | _IOC_WRITE, @"type", nr, @import("std").zig.c_translation.sizeof(size))) {
    _ = @TypeOf(size);
    return _IOC(_IOC_READ | _IOC_WRITE, @"type", nr, @import("std").zig.c_translation.sizeof(size));
}
pub inline fn _IOC_DIR(nr: anytype) @TypeOf((nr >> _IOC_DIRSHIFT) & _IOC_DIRMASK) {
    return (nr >> _IOC_DIRSHIFT) & _IOC_DIRMASK;
}
pub inline fn _IOC_TYPE(nr: anytype) @TypeOf((nr >> _IOC_TYPESHIFT) & _IOC_TYPEMASK) {
    return (nr >> _IOC_TYPESHIFT) & _IOC_TYPEMASK;
}
pub inline fn _IOC_NR(nr: anytype) @TypeOf((nr >> _IOC_NRSHIFT) & _IOC_NRMASK) {
    return (nr >> _IOC_NRSHIFT) & _IOC_NRMASK;
}
pub inline fn _IOC_SIZE(nr: anytype) @TypeOf((nr >> _IOC_SIZESHIFT) & _IOC_SIZEMASK) {
    return (nr >> _IOC_SIZESHIFT) & _IOC_SIZEMASK;
}
pub const IOC_IN = _IOC_WRITE << _IOC_DIRSHIFT;
pub const IOC_OUT = _IOC_READ << _IOC_DIRSHIFT;
pub const IOC_INOUT = (_IOC_WRITE | _IOC_READ) << _IOC_DIRSHIFT;
pub const IOCSIZE_MASK = _IOC_SIZEMASK << _IOC_SIZESHIFT;
pub const IOCSIZE_SHIFT = _IOC_SIZESHIFT;
pub const APM_IOC_STANDBY = _IO('A', @as(c_int, 1));
pub const APM_IOC_SUSPEND = _IO('A', @as(c_int, 2));
pub const _LINUX_EDD_H = "";
pub const EDDNR = @as(c_int, 0x1e9);
pub const EDDBUF = @as(c_int, 0xd00);
pub const EDDMAXNR = @as(c_int, 6);
pub const EDDEXTSIZE = @as(c_int, 8);
pub const EDDPARMSIZE = @as(c_int, 74);
pub const CHECKEXTENSIONSPRESENT = @as(c_int, 0x41);
pub const GETDEVICEPARAMETERS = @as(c_int, 0x48);
pub const LEGACYGETDEVICEPARAMETERS = @as(c_int, 0x08);
pub const EDDMAGIC1 = @as(c_int, 0x55AA);
pub const EDDMAGIC2 = @import("std").zig.c_translation.promoteIntLiteral(c_int, 0xAA55, .hexadecimal);
pub const READ_SECTORS = @as(c_int, 0x02);
pub const EDD_MBR_SIG_OFFSET = @as(c_int, 0x1B8);
pub const EDD_MBR_SIG_BUF = @as(c_int, 0x290);
pub const EDD_MBR_SIG_MAX = @as(c_int, 16);
pub const EDD_MBR_SIG_NR_BUF = @as(c_int, 0x1ea);
pub const EDD_EXT_FIXED_DISK_ACCESS = @as(c_int, 1) << @as(c_int, 0);
pub const EDD_EXT_DEVICE_LOCKING_AND_EJECTING = @as(c_int, 1) << @as(c_int, 1);
pub const EDD_EXT_ENHANCED_DISK_DRIVE_SUPPORT = @as(c_int, 1) << @as(c_int, 2);
pub const EDD_EXT_64BIT_EXTENSIONS = @as(c_int, 1) << @as(c_int, 3);
pub const EDD_INFO_DMA_BOUNDARY_ERROR_TRANSPARENT = @as(c_int, 1) << @as(c_int, 0);
pub const EDD_INFO_GEOMETRY_VALID = @as(c_int, 1) << @as(c_int, 1);
pub const EDD_INFO_REMOVABLE = @as(c_int, 1) << @as(c_int, 2);
pub const EDD_INFO_WRITE_VERIFY = @as(c_int, 1) << @as(c_int, 3);
pub const EDD_INFO_MEDIA_CHANGE_NOTIFICATION = @as(c_int, 1) << @as(c_int, 4);
pub const EDD_INFO_LOCKABLE = @as(c_int, 1) << @as(c_int, 5);
pub const EDD_INFO_NO_MEDIA_PRESENT = @as(c_int, 1) << @as(c_int, 6);
pub const EDD_INFO_USE_INT13_FN50 = @as(c_int, 1) << @as(c_int, 7);
pub const _ASM_X86_IST_H = "";
pub const __linux_video_edid_h__ = "";
pub const E820_MAX_ENTRIES_ZEROPAGE = @as(c_int, 128);
pub const JAILHOUSE_SETUP_REQUIRED_VERSION = @as(c_int, 1);
pub const screen_info = struct_screen_info;
pub const apm_bios_info = struct_apm_bios_info;
pub const edd_device_params = struct_edd_device_params;
pub const edd_info = struct_edd_info;
pub const edd = struct_edd;
pub const ist_info = struct_ist_info;
pub const edid_info = struct_edid_info;
pub const setup_data = struct_setup_data;
pub const setup_indirect = struct_setup_indirect;
pub const setup_header = struct_setup_header;
pub const sys_desc_table = struct_sys_desc_table;
pub const olpc_ofw_header = struct_olpc_ofw_header;
pub const efi_info = struct_efi_info;
pub const boot_e820_entry = struct_boot_e820_entry;
pub const jailhouse_setup_data = struct_jailhouse_setup_data;
pub const boot_params = struct_boot_params;
pub const x86_hardware_subarch = enum_x86_hardware_subarch;
