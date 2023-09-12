const std = @import("std");
const mem = std.mem;
const c = @cImport({
    @cInclude("linux/virtio_ring.h");
});
const kvm = @import("root").kvm;
const fs = std.fs;
const os = std.os;

pub const Q = struct {
    pfn: u32, // page frame number
    size: u32, // number of elements in the queue
    base: []volatile u8,
    ring: c.vring,
    last_avail: u16 = 0,
    last_used_signalled: u16 = 0,
    eventfd: fs.File,
    support_event_idx: bool,

    pub const Desc = struct {
        table: ?[]c.vring_desc,
        id: u16,
        desc: c.vring_desc,
    };

    const Self = @This();

    pub fn init(pfn: u32, size: u32, alignment: u32, features: u64, specified_page_size: ?u32) !Self {
        const ram = kvm.getMem();
        const offset = pfn * if (specified_page_size) |page_sz| page_sz else mem.page_size;
        var ring: c.vring = undefined;
        c.vring_init(&ring, size, ram.ptr + offset, alignment);
        const base = ram[offset .. offset + c.vring_size(size, alignment)];
        const f: fs.File = .{
            .handle = try os.eventfd(0, 0),
            .capable_io_mode = .blocking,
            .intended_io_mode = .blocking,
        };
        return Self{
            .pfn = pfn,
            .size = size,
            .base = base,
            .ring = ring,
            .eventfd = f,
            .support_event_idx = (features & (1 << c.VIRTIO_RING_F_EVENT_IDX)) != 0,
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
        if (self.ring.avail == null) return null;
        if (self.support_event_idx) @as(*volatile u16, @ptrCast(self.ring.used.*.ring() + self.ring.num)).* = self.last_avail;
        if (self.last_avail == self.ring.avail.*.idx) return null;
        //std.debug.print("{} {}\n", .{ self.last_avail, self.ring.avail.*.idx });

        defer self.last_avail +%= 1;
        const i = self.ring.avail.*.ring()[self.last_avail % self.ring.num];
        const d = Desc{
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

    pub fn getNext(self: *const Self, d: Desc) ?Desc {
        if (d.desc.flags & c.VRING_DESC_F_INDIRECT != 0) {
            const max = d.desc.len / @sizeOf(c.vring_desc);
            const ram = kvm.getMem();
            const table = @as([*]c.vring_desc, @alignCast(@ptrCast(ram.ptr + d.desc.addr)))[0..max];
            return Desc{
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
