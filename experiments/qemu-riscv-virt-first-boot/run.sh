#!/usr/bin/env bash
# 零交叉工具链的 QEMU RISC-V 全系统模拟最小实验
# 依赖：qemu（含 qemu-system-riscv64 / qemu-img）、dtc（可选，用于读 DTB）
# 用法：./run.sh | tee run1.log
set -u

QEMU=qemu-system-riscv64
BOOT_WAIT=4
OUT=./output

# macOS 没有 timeout，用后台进程 + sleep + kill 做有界运行
run_with_timeout() {
  local secs=$1; shift
  "$@" &
  local pid=$!
  sleep "$secs"
  kill -INT "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}

mkdir -p "$OUT"

echo '===== 1. 版本：确认 QEMU 已安装 ====='
"$QEMU" --version | head -1
echo

echo '===== 2. 机器模型：virt 是 RISC-V 的通用虚拟开发板 ====='
"$QEMU" -machine help | grep -E '^virt'
echo

echo '===== 3. 首次启动：-bios default 用 QEMU 内置 OpenSBI，无需任何编译器 ====='
echo "（虚拟机运行 ${BOOT_WAIT} 秒后自动结束）"
echo "+ $QEMU -machine virt -bios default -nographic -serial mon:stdio -no-reboot"
run_with_timeout "$BOOT_WAIT" \
  "$QEMU" -machine virt -bios default -nographic -serial mon:stdio -no-reboot
echo

echo '===== 4. 导出 virt 机器的设备树（DTB），看看这块虚拟板上有什么 ====='
"$QEMU" -machine virt,dumpdtb="$OUT/virt.dtb" -display none
if command -v dtc >/dev/null 2>&1; then
  dtc -I dtb -O dts "$OUT/virt.dtb" | grep -E '^\s*(model|compatible|interrupt-controller|serial|virtio_mmio)' | head -12
else
  ls -lh "$OUT/virt.dtb"
fi
echo

echo '===== 5. 创建 qcow2 磁盘镜像（后续装 Linux 发行版用） ====='
qemu-img create -f qcow2 "$OUT/disk.qcow2" 64M
qemu-img info "$OUT/disk.qcow2" | grep -E 'file format|virtual size|disk size'
echo

echo '===== 全部步骤完成；产物在 output/（已 gitignore） ====='
