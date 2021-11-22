var next: u8 = 5;
pub fn alloc() u8 {
    defer next += 1;
    return next;
}
