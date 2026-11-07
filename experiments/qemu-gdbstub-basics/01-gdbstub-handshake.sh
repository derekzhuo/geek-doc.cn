#!/usr/bin/env bash
# 实验 1：gdbstub 握手——-s -S 冻结在复位向量，QMP 看 prelaunch，gdb 连上读寄存器
# 对应教程：https://geek-doc.cn/soc-qemu/qemu-gdbstub-how-it-works.html
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"

OUT="$DIR/output/01"
mkdir -p "$OUT"

echo '===== 1. 版本基座 ====='
run "$QEMU" --version
run "$GDB" --version

echo
echo '===== 2. 启动冻结虚拟机：-s 开 1234 gdbstub，-S 让 CPU 一条指令都不跑 ====='
start_qemu "$OUT"
echo "qemu pid=${QEMU_PID}，gdbstub 端口 ${GDPPORT} 已监听"

echo
echo '===== 3. gdb 连接前，QMP 视角的状态是 prelaunch（running=false）====='
qmp_query

echo
echo '===== 4. gdb 批处理连接：握手成功后读 PC 与全部通用寄存器 ====='
gdb_session \
  -ex 'info registers pc' \
  -ex 'info registers'

echo
echo '===== 5. 收掉虚拟机 ====='
stop_qemu
echo '实验 1 完成：PC=0x1000 是 virt 机器复位向量，寄存器全零证明冻结发生在第一条指令之前。'
