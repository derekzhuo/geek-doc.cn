#!/usr/bin/env bash
# 一条完整 QEMU 启动命令的逐参数实验：机器/固件/内存/核数/磁盘/控制台各参数真实生效取证
# 依赖：qemu（含 qemu-system-riscv64 / qemu-img）
# 用法：./run.sh | tee run1.log
set -u

QEMU=qemu-system-riscv64
IMG=qemu-img
BOOT_WAIT=5
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

echo '===== 1. 版本与机器模型：确认实验基座 ====='
"$QEMU" --version | head -1
"$QEMU" -machine help | grep -E '^virt'
echo

echo '===== 2. 准备一块 qcow2 数据盘，供 -drive/-device 挂载 ====='
"$IMG" create -f qcow2 "$OUT/disk.qcow2" 64M
"$IMG" info "$OUT/disk.qcow2" | grep -E 'file format|virtual size|disk size'
echo

echo '===== 3. 完整启动命令（运行 5 秒后自动结束）====='
FULL_CMD=(
  "$QEMU" -machine virt -bios default -m 256M -smp 2
  -nographic -serial mon:stdio -no-reboot
  -drive "file=$OUT/disk.qcow2,if=none,id=drive0,format=qcow2"
  -device virtio-blk-device,drive=drive0
)
echo "+ ${FULL_CMD[*]}"
run_with_timeout "$BOOT_WAIT" "${FULL_CMD[@]}"
echo

echo '===== 4. 可选 CPU 模型列表：不写 -cpu 时 virt 用默认 rv64 ====='
"$QEMU" -cpu help | head -8
echo

echo '===== 5. 内存参数后缀说明：-m 支持的单位 ====='
"$QEMU" -m help | head -6
echo

echo '===== 全部步骤完成；产物在 output/（已 gitignore） ====='
