#!/bin/bash
# 在无 KVM 能力的主机上复现三类报错，并证明 TCG 仍可兜底
# 仅适合一次性虚拟机/实验机；脚本结束会清理自建的 /dev/kvm 占位节点
set -u

echo "### 环境事实：CPU 无虚拟化标志（无输出即没有 vmx/svm）"
grep -o -E 'vmx|svm' /proc/cpuinfo | sort -u || true

echo
echo "### 报错类 1：厂商模块加载失败（通用 kvm 能加载，kvm_intel 被拒）"
sudo modprobe kvm; echo "modprobe kvm exit=$?"
sudo modprobe kvm_intel; echo "modprobe kvm_intel exit=$?"

echo
echo "### 报错类 2：/dev/kvm 不存在时 -enable-kvm"
ls /dev/kvm 2>&1 || true
qemu-system-x86_64 -enable-kvm -machine q35 -nographic -S <<< '' 2>&1 | head -3 || true

echo
echo "### 报错类 3：建一个 root:600 的占位 /dev/kvm，复现权限拒绝"
[ -e /dev/kvm ] || sudo mknod /dev/kvm c 10 232
sudo chmod 600 /dev/kvm
ls -l /dev/kvm
qemu-system-x86_64 -enable-kvm -machine q35 -nographic -S <<< '' 2>&1 | head -3 || true

echo
echo "### 对照：chmod 666 后错误类型变成 No such device（ioctl 失败，证明节点只是占位）"
sudo chmod 666 /dev/kvm
qemu-system-x86_64 -enable-kvm -machine q35 -nographic -S <<< '' 2>&1 | head -3 || true

echo
echo "### 清理占位节点"
sudo rm -f /dev/kvm
ls /dev/kvm 2>&1 || true

echo
echo "### TCG 兜底：同机无 KVM 仍可纯软件模拟"
qemu-system-x86_64 -accel help
