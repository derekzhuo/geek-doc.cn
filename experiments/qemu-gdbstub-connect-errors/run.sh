#!/usr/bin/env bash
# 复现 gdb 连不上 QEMU gdbstub 的三类现场，并附一组健康连接对照：
#   1. healthy      正常 -s -S，gdb 干净连上并读到复位 PC
#   2. no-stub      QEMU 未开 -s，gdb 连接超时失败（macOS 文案）
#   3. port-busy    两台 QEMU 同时抢 1234，第二台 gdbstub 建不起来
#   4. arch-mismatch gdb 误配 riscv:rv32 连 rv64 目标，ambiguous 告警
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"
OUT="$DIR/output/run"
mkdir -p "$OUT"
exec 2>&1

printf 'TOOL_VERSION: '
"$QEMU" --version | head -1
"$GDB" --version | head -1

echo
echo '===== 1. healthy: -s -S 冻结启动，gdb 干净连接并读 PC ====='
start_qemu "$OUT/healthy" on
sleep 0.5
gdb_session 'riscv:rv64' -ex 'info registers pc'
printf 'CASE_EXIT healthy=%s\n' "$?"
stop_qemu

echo
echo '===== 2. no-stub: 启动参数不带 -s，1234 无监听，gdb 连接失败 ====='
start_qemu "$OUT/nostub" off
sleep 0.5
gdb_session 'riscv:rv64' -ex 'info registers pc'
printf 'CASE_EXIT no_stub=%s\n' "$?"
stop_qemu

echo
echo '===== 3. port-busy: 第一台占用 1234，第二台 -s 抢端口失败 ====='
start_qemu "$OUT/busy1" on
"$QEMU" -machine virt -bios default -display none -s -S </dev/null 2>"$OUT/busy2.err" &
BUSY_PID=$!
wait "$BUSY_PID"
BUSY_RC=$?
cat "$OUT/busy2.err"
printf 'CASE_EXIT port_busy=%s（第二台 QEMU 因 1234 被占自行退出，gdbstub chardev 创建失败）\n' "$BUSY_RC"
stop_qemu

echo
echo '===== 4. arch-mismatch: gdb 误设 riscv:rv32 连 rv64 目标，触发 ambiguous 告警 ====='
start_qemu "$OUT/arch" on
sleep 0.5
gdb_session 'riscv:rv32' -ex 'info registers pc'
printf 'CASE_EXIT arch_mismatch=%s（gdb 不断连，但按错误位宽解读，修法是改回 rv64/auto）\n' "$?"
stop_qemu

echo
echo '全部四组完成：健康连接退出码 0；无 stub 连接失败；端口占用第二台 QEMU 报 chardev 创建失败；架构误配仅告警不断连。'
