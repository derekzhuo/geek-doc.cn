#!/bin/bash
# Rocky / RHEL 系（容器或实体机内执行）：包名与 apt 系不同，主程序在 /usr/libexec/qemu-kvm
set -e
dnf search qemu | grep -E 'qemu-(kvm|img)' || true

# 注意：不存在 qemu-device-display-virtio-gpu 这个包名，
# 写错包名 dnf 会整单中止，先按最小可用集合安装。
dnf install -y qemu-kvm qemu-img

echo "=== 版本核验 ==="
qemu-img --version | head -1
ls -l /usr/libexec/qemu-kvm
/usr/libexec/qemu-kvm --version | head -1
