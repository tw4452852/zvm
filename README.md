# zvm
Stand-alone Native Linux KVM with Zig

# Build

```
zig build
```

# Run

Just run with stand-alone linux kernel:

```
zvm -kernel /path/to/bzImage
```

Also with an `initrd`:

```
zvm -kernel /path/to/bzImage -initrd /path/to/initrd
```

You could also specify the kernel cmdline:

```
zvm -kernel /path/to/bzImage -cmdline "console=ttyS0 ..."
```

Attach a disk:

```
zvm -kernel /path/to/bzImage -b /path/to/disk.img
```

Attach a NIC:

```
zvm -kernel /path/to/bzImage -n
```
