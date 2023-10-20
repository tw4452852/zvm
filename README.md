# zvm
A KVM frontend written in Zig

## Build

For native:
```
zig build
```

Or cross-compile for arm64:
```
zig build -Dtarget=aarch64-linux
```

## Run

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

Attach a virtual disk:

```
zvm -kernel /path/to/bzImage -b /path/to/disk.img
```

Attach a virtual NIC:

```
zvm -kernel /path/to/bzImage -n
```

## Functionalities

| | x86-64 | arm64
| --- | --- | ---
|boot|:heavy_check_mark:|:heavy_check_mark:
|smp|:heavy_check_mark:|:heavy_check_mark:
|initrd|:heavy_check_mark:|:heavy_check_mark:
|serial|:heavy_check_mark:|:heavy_check_mark:
|mmio|:heavy_check_mark:|:heavy_check_mark:
|pci|:x:|:heavy_check_mark:
|MSI-X|:x:|:heavy_check_mark:
|virtio-mmio|:heavy_check_mark:|:heavy_check_mark:
|virtio-pci-modern|:x:|:heavy_check_mark:
|virtio-blk|:heavy_check_mark:|:heavy_check_mark:
|virtio-net|:heavy_check_mark:|:heavy_check_mark:
|vhost-net|:heavy_check_mark:|:heavy_check_mark:
