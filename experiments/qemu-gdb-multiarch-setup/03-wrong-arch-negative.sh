#!/usr/bin/env bash
# 实验 3：架构误配阴性对照——把 gdb 误设成 riscv:rv32 连 rv64 虚拟机，
# 抓 gdbstub 上报架构与本地选择不一致时的真实告警；再用 auto 探测恢复干净连接。
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"
OUT="$DIR/output/03"

echo '===== 1. 启动冻结的 rv64 虚拟机 ====='
start_qemu "$OUT"
echo "qemu pid=${QEMU_PID}"

echo
echo '===== 2. 误配 riscv:rv32 连接：gdbstub 上报 rv64，触发 ambiguous 告警 ====='
run "$GDB" -q -nx -batch \
  -ex 'set architecture riscv:rv32' \
  -ex "target remote :$GDPPORT" \
  -ex 'info registers pc' || true

stop_qemu
echo
echo '===== 3. 同一台虚拟机重新起，用 auto 让 gdb 按 stub 上报自动选架构 ====='
start_qemu "$OUT"
run "$GDB" -q -nx -batch \
  -ex 'set architecture auto' \
  -ex "target remote :$GDPPORT" \
  -ex 'show architecture' \
  -ex 'info registers pc'

stop_qemu
echo
echo '实验 3 完成：架构不一致不会立刻断开，但反汇编/寄存器位宽会按错误位宽解读；auto 或显式 rv64 才是干净连接。'
