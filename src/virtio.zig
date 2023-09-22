const std = @import("std");
const mem = std.mem;
const c = @cImport({
    @cInclude("linux/virtio_ring.h");
    @cInclude("linux/virtio_config.h");
});
const kvm = @import("root").kvm;
const fs = std.fs;
const os = std.os;

pub const Q = struct {
    ring: union(enum) {
        split: SplitQ,
        pack: PackedQ,
    },
    eventfd: fs.File,

    pub const InitV1 = struct {
        pfn: u32,
    };

    pub const InitV2 = struct {
        descs_addr: u64,
        avail_addr: u64,
        used_addr: u64,
    };

    pub const InitVersion = union(enum) {
        v1: InitV1,
        v2: InitV2,
    };

    pub const Desc = struct {
        table: ?[]c.vring_desc,
        id: u16,
        desc: c.vring_desc,
    };

    const Self = @This();

    pub fn init(ver: InitVersion, size: u32, alignment: u32, features: u64, specified_page_size: ?u32, eventfd: os.fd_t) !Self {
        const use_packed = (features & (1 << c.VIRTIO_F_RING_PACKED)) != 0;
        const support_event_idx = (features & (1 << c.VIRTIO_RING_F_EVENT_IDX)) != 0;

        const f: fs.File = .{
            .handle = eventfd,
            .capable_io_mode = .blocking,
            .intended_io_mode = .blocking,
        };

        return Self{
            .ring = if (use_packed)
                .{ .pack = try PackedQ.init(ver, size, alignment, specified_page_size, support_event_idx) }
            else
                .{ .split = try SplitQ.init(ver, size, alignment, specified_page_size, support_event_idx) },
            .eventfd = f,
        };
    }

    pub fn deinit(self: *Self) void {
        self.eventfd.close();
        self.* = undefined;
    }

    pub fn waitAvail(self: *Self) !void {
        const reader = self.eventfd.reader();
        while (true) {
            const n = try reader.readIntNative(u64);
            if (n > 0) break;
        }
    }

    pub fn notifyAvail(self: *Self) !void {
        try self.eventfd.writer().writeIntNative(u64, 1);
    }

    pub fn getAvail(self: *Self) ?Desc {
        switch (self.ring) {
            .split => |*r| return r.getAvail(),
            .pack => |*r| return r.getAvail(),
        }
    }

    pub fn getNext(self: *const Self, d: Desc) ?Desc {
        switch (self.ring) {
            .split => |*r| return r.getNext(d),
            .pack => |*r| return r.getNext(d),
        }
    }

    pub fn putUsed(self: *Self, used: anytype) void {
        switch (self.ring) {
            .split => |*r| return r.putUsed(.{ .id = used.id, .len = used.len }),
            .pack => |*r| return r.putUsed(.{ .id = used.id, .len = used.len }),
        }
    }

    pub fn need_notify(self: *Self) bool {
        switch (self.ring) {
            .split => |*r| return r.need_notify(),
            .pack => |*r| return r.need_notify(),
        }
    }
};

const PackedQ = struct {
    const Self = @This();

    ready: bool = false,

    pub fn init(ver: Q.InitVersion, size: u32, alignment: u32, specified_page_size: ?u32, support_event_idx: bool) !Self {
        _ = ver;
        _ = size;
        _ = alignment;
        _ = specified_page_size;
        _ = support_event_idx;

        @panic("todo");
    }

    pub fn getAvail(self: *Self) ?Q.Desc {
        _ = self;
        @panic("todo");
    }

    pub fn getNext(self: *const Self, d: Q.Desc) ?Q.Desc {
        _ = self;
        _ = d;
        @panic("todo");
    }

    pub fn putUsed(self: *Self, used: c.vring_used_elem) void {
        _ = self;
        _ = used;
        @panic("todo");
    }

    pub fn need_notify(self: *const Self) bool {
        _ = self;
        @panic("todo");
    }
};

const SplitQ = struct {
    const Self = @This();

    pfn: ?u32,
    ring: c.vring,
    last_avail: u16 = 0,
    last_used_signalled: u16 = 0,
    support_event_idx: bool,

    pub fn init(ver: Q.InitVersion, size: u32, alignment: u32, specified_page_size: ?u32, support_event_idx: bool) !Self {
        var ring: c.vring = undefined;
        const ram = kvm.getMem();

        var pfn: ?u32 = null;
        switch (ver) {
            .v1 => |args| {
                pfn = args.pfn;
                const offset = args.pfn * if (specified_page_size) |page_sz| page_sz else mem.page_size;
                c.vring_init(&ring, size, ram.ptr + offset, alignment);
            },
            .v2 => |args| {
                c.vring_init(&ring, size, ram.ptr + args.descs_addr, alignment);
                ring.avail = @alignCast(@ptrCast(ram.ptr + args.avail_addr));
                ring.used = @alignCast(@ptrCast(ram.ptr + args.used_addr));
            },
        }

        return Self{
            .ring = ring,
            .pfn = pfn,
            .support_event_idx = support_event_idx,
        };
    }

    fn getAvail(self: *Self) ?Q.Desc {
        if (self.ring.avail == null) return null;
        if (self.support_event_idx) @as(*volatile u16, @ptrCast(self.ring.used.*.ring() + self.ring.num)).* = self.last_avail;
        if (self.last_avail == self.ring.avail.*.idx) return null;
        //std.debug.print("{} {}\n", .{ self.last_avail, self.ring.avail.*.idx });

        defer self.last_avail +%= 1;
        const i = self.ring.avail.*.ring()[self.last_avail % self.ring.num];
        const d = Q.Desc{
            .id = i,
            .desc = self.ring.desc[i],
            .table = null,
        };
        return if (d.desc.flags & c.VRING_DESC_F_INDIRECT != 0) self.getNext(d) else d;
    }

    pub fn putUsed(self: *Self, used: c.vring_used_elem) void {
        std.debug.assert(self.ring.used != null);
        const i = self.ring.used.*.idx;
        self.ring.used.*.ring()[i % self.ring.num] = used;
        @as(*volatile u16, @ptrCast(&self.ring.used.*.idx)).* = i +% 1;
        //std.debug.print("put {}\n", .{i +% 1});
    }

    pub fn getNext(self: *const Self, d: Q.Desc) ?Q.Desc {
        if (d.desc.flags & c.VRING_DESC_F_INDIRECT != 0) {
            const max = d.desc.len / @sizeOf(c.vring_desc);
            const ram = kvm.getMem();
            const table = @as([*]c.vring_desc, @alignCast(@ptrCast(ram.ptr + d.desc.addr)))[0..max];
            return .{
                .id = d.id,
                .desc = table[0],
                .table = table,
            };
        }
        const next_i = d.desc.next;
        return if (d.desc.flags & c.VRING_DESC_F_NEXT != 0) .{
            .id = next_i,
            .desc = if (d.table) |table| table[next_i] else self.ring.desc[next_i],
            .table = d.table,
        } else null;
    }

    pub fn need_notify(self: *Self) bool {
        if (self.support_event_idx) {
            const old = self.last_used_signalled;
            const new = self.ring.used.*.idx;
            const evt = self.ring.avail.*.ring()[self.ring.num];
            const ret = c.vring_need_event(evt, new, old);

            if (ret == 1) {
                self.last_used_signalled = new;
                return true;
            } else {
                //std.debug.print("{}, {}, {} => {}\n", .{ old, new, evt, ret });
                return false;
            }
        } else {
            //std.debug.print("0x{x}\n", .{self.ring.avail.*.flags});
            return self.ring.avail.*.flags & c.VRING_AVAIL_F_NO_INTERRUPT == 0;
        }
    }
};
