#!/usr/bin/env bash
# QEMU monitor 实验：经 QMP 套接字查询运行态、块设备、CPU，打内部快照并从外部交叉验证
# 依赖：qemu（含 qemu-system-riscv64 / qemu-img）、nc（macOS 自带支持 -U Unix 套接字）
# 用法：./run.sh | tee run1.log
set -u

QEMU=qemu-system-riscv64
IMG=qemu-img
OUT=./output
SOCK="$OUT/qmp.sock"
DISK="$OUT/disk.qcow2"

mkdir -p "$OUT"
rm -f "$SOCK"

cleanup() {
  [ -n "${QPID:-}" ] && kill "$QPID" 2>/dev/null || true
  rm -f "$SOCK"
}
trap cleanup EXIT

echo '===== 1. 版本与数据盘准备 ====='
"$QEMU" --version | head -1
"$IMG" create -f qcow2 "$DISK" 64M
echo

echo '===== 2. 后台启动虚拟机，monitor 走 QMP Unix 套接字（无界面）====='
"$QEMU" -machine virt -bios default -display none \
  -qmp "unix:$SOCK,server,nowait" \
  -drive "file=$DISK,if=none,id=drive0,format=qcow2" \
  -device virtio-blk-device,drive=drive0 &
QPID=$!
for _ in $(seq 1 20); do
  [ -S "$SOCK" ] && break
  sleep 0.3
done
echo "qemu pid=$QPID, socket=$SOCK"
echo

echo '===== 3. QMP 握手与 query-status：机器协议返回干净 JSON ====='
echo '===== 4. 经 human-monitor-command 执行 HMP  info 命令族 ====='
echo '===== 5. savevm 打内部快照，观察 STOP/RESUME 事件 ====='
qmp() {
  echo "+ $1" >&2
  printf '%s\n' "$1"; sleep 0.4
}
{
  qmp '{"execute":"qmp_capabilities"}'
  qmp '{"execute":"query-status"}'
  qmp '{"execute":"human-monitor-command","arguments":{"command-line":"info status"}}'
  qmp '{"execute":"human-monitor-command","arguments":{"command-line":"info block"}}'
  qmp '{"execute":"human-monitor-command","arguments":{"command-line":"info cpus"}}'
  echo "+ savevm 给虚拟机留停顿时间，单独等 0.8 秒" >&2
  printf '%s\n' '{"execute":"human-monitor-command","arguments":{"command-line":"savevm snap1"}}'; sleep 0.8
  qmp '{"execute":"human-monitor-command","arguments":{"command-line":"info snapshots"}}'
  qmp '{"execute":"quit"}'
} | nc -U "$SOCK"
wait "$QPID" 2>/dev/null || true
QPID=""
echo

echo '===== 6. 虚拟机外部交叉验证：qemu-img 能看到 monitor 打的快照 ====='
"$IMG" snapshot -l "$DISK"
echo

echo '===== 全部步骤完成；产物在 output/（已 gitignore） ====='
