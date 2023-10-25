const std = @import("std");
const root = @import("root");
const os = std.os;
const kvm = root.kvm;
const ioctl = os.linux.ioctl;
const c = @import("root").c;
const check = @import("helpers.zig").check_non_zero;
const mem = std.mem;
const fs = std.fs;
const fmt = std.fmt;

var container_fd: os.fd_t = undefined;

const IOMMUType = enum(u8) {
    type1 = 1,
    spapr_tce = 2,
    type1v2 = 3,
    type1_nesting = 6,
    spapr_tce_v2 = 7,
    noiommu = 8,
};

const Group = struct {
    const Self = @This();

    fd: os.fd_t,
    id: usize,

    pub fn init(id: usize) !Self {
        var buf: [32]u8 = undefined;
        const path = try fmt.bufPrint(&buf, "/dev/vfio/{}", .{id});
        const f = try fs.cwd().openFile(path, .{
            .mode = .read_write,
        });

        var status = mem.zeroInit(c.vfio_group_status, .{
            .argsz = @sizeOf(c.vfio_group_status),
        });

        try check(ioctl(f.handle, c.VFIO_GROUP_GET_STATUS, @intFromPtr(&status)));

        if (status.flags & c.VFIO_GROUP_FLAGS_VIABLE == 0) {
            std.log.err("iommu group {} not viable", .{id});
            return error.IOMMU;
        }

        return .{
            .fd = f.handle,
            .id = id,
        };
    }

    pub fn attach_container(self: *const Self, container: os.fd_t) !void {
        try check(ioctl(self.fd, c.VFIO_GROUP_SET_CONTAINER, @intFromPtr(&container)));
    }

    pub fn deinit(self: *Self) void {
        os.close(self.fd);
        self.* = undefined;
    }
};

const GroupMap = std.AutoHashMap(usize, Group);
var groups: GroupMap = undefined;

const Dev = struct {
    const Self = @This();

    const BusType = enum {
        pci,
        platform,
    };

    bus: BusType,
    name: []const u8,
    group_id: usize,

    pub fn init(sysfs_path: []const u8) !Self {
        var iter = try fs.path.componentIterator(sysfs_path);
        try std.testing.expectEqualStrings("sys", iter.next().?.name);
        try std.testing.expectEqualStrings("bus", iter.next().?.name);
        const bus = std.meta.stringToEnum(BusType, iter.next().?.name).?;
        try std.testing.expectEqualStrings("devices", iter.next().?.name);
        const name = iter.next().?.name;

        // replace driver with vfio-*
        var buf: [128]u8 = undefined;
        const driver_override = try fmt.bufPrint(&buf, "/sys/bus/{s}/devices/{s}/driver_override", .{ @tagName(bus), name });
        try fs.cwd().writeFile(driver_override, switch (bus) {
            .pci => "vfio-pci",
            .platform => "vfio-platform",
        });
        const unbind = try fmt.bufPrint(&buf, "/sys/bus/{s}/devices/{s}/driver/unbind", .{ @tagName(bus), name });
        fs.cwd().writeFile(unbind, name) catch |err| switch (err) {
            std.fs.File.OpenError.FileNotFound => {},
            else => return err,
        };
        const drivers_probe = try fmt.bufPrint(&buf, "/sys/bus/{s}/drivers_probe", .{@tagName(bus)});
        try fs.cwd().writeFile(drivers_probe, name);

        const group_id = try get_iommu_group_id(bus, name);
        var ret: Self = .{
            .bus = bus,
            .name = name,
            .group_id = group_id,
        };
        errdefer ret.deinit();

        const gop = try groups.getOrPut(group_id);
        if (!gop.found_existing) {
            gop.value_ptr.* = try Group.init(group_id);
        }

        return ret;
    }

    fn get_iommu_group_id(bus: BusType, name: []const u8) !usize {
        var buf: [128]u8 = undefined;
        const iommu_group_link = try fmt.bufPrint(&buf, "/sys/bus/{s}/devices/{s}/iommu_group", .{ @tagName(bus), name });
        const link_target = try os.readlink(iommu_group_link, &buf);
        const s = fs.path.basename(link_target);

        return try fmt.parseInt(usize, s, 10);
    }

    pub fn deinit(self: *Self) void {
        // restore default driver
        var buf: [128]u8 = undefined;
        const driver_override = fmt.bufPrint(&buf, "/sys/bus/{s}/devices/{s}/driver_override", .{ @tagName(self.bus), self.name }) catch unreachable;
        fs.cwd().writeFile(driver_override, "\n") catch unreachable;
        const unbind = fmt.bufPrint(&buf, "/sys/bus/{s}/devices/{s}/driver/unbind", .{ @tagName(self.bus), self.name }) catch unreachable;
        fs.cwd().writeFile(unbind, self.name) catch unreachable;
        const drivers_probe = fmt.bufPrint(&buf, "/sys/bus/{s}/drivers_probe", .{@tagName(self.bus)}) catch unreachable;
        fs.cwd().writeFile(drivers_probe, self.name) catch unreachable;

        self.* = undefined;
    }
};

const max_devs = 64;
var devs: [max_devs]Dev = undefined;
var dev_count: usize = 0;

pub fn init(allocator: std.mem.Allocator, paths: [][]const u8) !void {
    try_load_module(allocator, &.{ "modprobe", "vfio_iommu_type1", "allow_unsafe_interrupts=1" });
    try_load_module(allocator, &.{ "modprobe", "vfio-pci" });
    try_load_module(allocator, &.{ "modprobe", "vfio-platform", "reset_required=0" });

    groups = GroupMap.init(allocator);

    for (paths) |path| {
        devs[dev_count] = try Dev.init(path);
        dev_count += 1;
    }
    errdefer deinit();

    try init_container();
    try setup_container_iommu_mapping(allocator);
}

fn add_container_iommu_mapping(start: usize, end: usize) !void {
    // add mapping between iova(gpa) and hpa
    const guest_mem = kvm.getMem();
    if (start < guest_mem.len) {
        const size = @min(guest_mem.len - start, end - start + 1);
        const dma_map: c.vfio_iommu_type1_dma_map = .{
            .argsz = @sizeOf(c.vfio_iommu_type1_dma_map),
            .flags = c.VFIO_DMA_MAP_FLAG_READ | c.VFIO_DMA_MAP_FLAG_WRITE,
            .vaddr = @intFromPtr(guest_mem.ptr + start), // hva, kernel will pin pages to get the hpa
            .iova = start, // gpa
            .size = size,
        };
        try check(ioctl(container_fd, c.VFIO_IOMMU_MAP_DMA, @intFromPtr(&dma_map)));
    }
}

fn setup_container_iommu_mapping(allocator: std.mem.Allocator) !void {
    var info = try allocator.create(c.vfio_iommu_type1_info);
    defer allocator.destroy(info);

    @memset(mem.asBytes(info), 0);
    info.argsz = @sizeOf(c.vfio_iommu_type1_info);

    try check(ioctl(container_fd, c.VFIO_IOMMU_GET_INFO, @intFromPtr(info)));

    if (info.flags & c.VFIO_IOMMU_INFO_PGSIZES != 0) {
        std.log.info("iommu pagesize: 0x{x}", .{info.iova_pgsizes});
    } else std.log.info("can't find iommu page size", .{});

    if (info.argsz > @sizeOf(c.vfio_iommu_type1_info)) {
        info = @ptrCast(try allocator.realloc(mem.asBytes(info), info.argsz));
        try check(ioctl(container_fd, c.VFIO_IOMMU_GET_INFO, @intFromPtr(info)));

        var cap: *const c.vfio_info_cap_header = @alignCast(@ptrCast(mem.asBytes(info)[info.cap_offset..][0..@sizeOf(c.vfio_info_cap_header)]));

        while (true) {
            switch (cap.id) {
                c.VFIO_IOMMU_TYPE1_INFO_CAP_IOVA_RANGE => {
                    const iova_range: *align(1) const c.vfio_iommu_type1_info_cap_iova_range = @ptrCast(cap);
                    const ranges: [*]align(1) const c.vfio_iova_range = @ptrCast(mem.asBytes(cap).ptr + 16);

                    for (0..iova_range.nr_iovas) |i| {
                        std.log.info("iova range: 0x{x} - 0x{x}", .{ ranges[i].start, ranges[i].end });
                        try add_container_iommu_mapping(ranges[i].start, ranges[i].end);
                    }
                },
                c.VFIO_IOMMU_TYPE1_INFO_CAP_MIGRATION => {},
                c.VFIO_IOMMU_TYPE1_INFO_DMA_AVAIL => {},
                else => unreachable,
            }

            if (cap.next == 0) break;
            cap = @alignCast(@ptrCast(mem.asBytes(info)[cap.next..][0..@sizeOf(c.vfio_info_cap_header)]));
        }
    }
}

fn try_load_module(allocator: std.mem.Allocator, args: []const []const u8) void {
    const res = std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = args,
    }) catch |err| {
        std.log.info("{}", .{err});
        return;
    };

    switch (res.term) {
        .Exited => |code| if (code == 0) return,
        else => {},
    }

    std.log.info("{s}", .{res.stdout});
    std.log.info("{s}", .{res.stderr});

    allocator.free(res.stdout);
    allocator.free(res.stderr);
}

fn init_container() !void {
    const f = try fs.cwd().openFile("/dev/vfio/vfio", .{
        .mode = .read_write,
    });

    const version = ioctl(f.handle, c.VFIO_GET_API_VERSION, 0);
    std.log.info("vfio version = {}", .{version});

    const iommu_type = get_iommu_type(f.handle);

    var it = groups.valueIterator();
    while (it.next()) |group| {
        try group.attach_container(f.handle);
    }

    // finalize container
    try check(ioctl(f.handle, c.VFIO_SET_IOMMU, @intFromEnum(iommu_type)));
    std.log.info("iommu type = {}", .{iommu_type});

    container_fd = f.handle;
}

fn get_iommu_type(container: os.fd_t) IOMMUType {
    if (ioctl(container, c.VFIO_CHECK_EXTENSION, c.VFIO_TYPE1v2_IOMMU) > 0) return .type1v2;
    if (ioctl(container, c.VFIO_CHECK_EXTENSION, c.VFIO_TYPE1_IOMMU) > 0) return .type1;

    unreachable;
}

pub fn deinit() void {
    var it = groups.valueIterator();
    while (it.next()) |group| {
        group.deinit();
    }
    groups.deinit();
    for (devs[0..dev_count]) |*dev| {
        dev.deinit();
    }
    os.close(container_fd);
}
