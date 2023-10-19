const root = @import("root");
const Arch = root.Arch;

var next: u32 = Arch.start_irq;

pub fn alloc() u32 {
    defer next += 1;
    return next;
}

pub fn gsi(irq: u32) u32 {
	return irq - Arch.start_irq;
}
