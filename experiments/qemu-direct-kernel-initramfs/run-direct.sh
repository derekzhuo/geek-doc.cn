#!/bin/bash
# 不带 expect 的等价启动命令，适合手动观察串口
set -u
IMG=${VM_IMG:-$PWD/noble-server-cloudimg-riscv64.img}
BIOS=/usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.bin
timeout 480 qemu-system-riscv64 \
  -machine virt -m 2048 -smp 2 -nographic \
  -bios "$BIOS" \
  -kernel vmlinuz -initrd initrd.img \
  -append "root=LABEL=cloudimg-rootfs ro rootwait earlycon console=ttyS0 systemd.mask=boot-efi.mount systemd.mask=systemd-networkd-wait-online.service" \
  -drive file="$IMG",if=virtio,format=qcow2
echo "QEMU_EXIT=$?"
