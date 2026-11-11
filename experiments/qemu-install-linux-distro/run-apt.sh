#!/bin/bash
# Ubuntu / Debian 系：一次装齐 system 态、user 态、工具、固件与设备树编译器
set -e
sudo apt-get update
sudo apt-get install -y \
  qemu-system qemu-system-misc \
  qemu-user qemu-user-static \
  qemu-utils \
  opensbi u-boot-qemu \
  device-tree-compiler

echo "=== 包清单与版本 ==="
dpkg -l | grep -E 'qemu|opensbi|device-tree-compiler|u-boot' | awk '{print $2, $3}'

echo "=== 二进制版本 ==="
qemu-system-riscv64 --version | head -1
qemu-riscv64 --version | head -1
qemu-img --version | head -1
