#!/bin/bash
# 从 Ubuntu Noble RISC-V 云镜像准备可启动磁盘：
# 取内核/initrd、写入口令 hash、补 DHCP netplan、修 extlinux 控制台参数
# 依赖：qemu-utils(nbd)、openssl；需要 sudo
set -eux

IMG=${1:-noble-server-cloudimg-riscv64.img}
PW=${2:-riscv-demo-pw}

[ -f "$IMG" ] || curl -fLO "https://cloud-images.ubuntu.com/noble/current/$IMG"

sudo modprobe nbd max_part=32
sudo qemu-nbd --connect=/dev/nbd0 "$IMG"
sleep 2
# p1=rootfs(cloudimg-rootfs) p15=UEFI(FAT) p16=BOOT(ext4，内核与 extlinux)
sudo mkdir -p /mnt/noble /mnt/boot
sudo mount /dev/nbd0p1 /mnt/noble
sudo mount /dev/nbd0p16 /mnt/boot

# 1. 取出内核与 initramfs（直挂内核引导用）
cp /mnt/boot/vmlinuz-* ./vmlinuz
cp /mnt/boot/initrd.img ./initrd.img

# 2. 直接写 /etc/shadow，避免依赖 cloud-init
HASH=$(openssl passwd -6 "$PW")
sudo cp /mnt/noble/etc/shadow /mnt/noble/etc/shadow.bak
sudo python3 - "$HASH" <<'PY'
import sys
h = sys.argv[1]
p = "/mnt/noble/etc/shadow"
lines = open(p).read().splitlines()
out = []
for ln in lines:
    if ln.startswith("ubuntu:"):
        f = ln.split(":")
        f[1] = h
        ln = ":".join(f)
    out.append(ln)
open(p, "w").write("\n".join(out) + "\n")
PY

# 3. 云镜像 netplan 默认空目录，补一份 DHCP 配置
sudo tee /mnt/noble/etc/netplan/01-dhcp.yaml >/dev/null <<'YAML'
network:
  version: 2
  ethernets:
    all-eth:
      match:
        name: "en*"
      dhcp4: true
      optional: true
YAML
sudo chmod 600 /mnt/noble/etc/netplan/01-dhcp.yaml

# 4. extlinux 补串口控制台，并 mask 掉无 EFI 分区场景下的失败单元
sudo sed -i \
  's|append root=LABEL=cloudimg-rootfs ro earlycon|append root=LABEL=cloudimg-rootfs ro earlycon console=ttyS0 systemd.mask=boot-efi.mount systemd.mask=systemd-networkd-wait-online.service|' \
  /mnt/boot/extlinux/extlinux.conf

sudo umount /mnt/noble /mnt/boot
sudo qemu-nbd --disconnect /dev/nbd0
echo "PREPARE_DONE: vmlinuz/initrd 已取出，镜像可直接引导"
