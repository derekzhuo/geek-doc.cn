#!/usr/bin/env bash
# 实验 2：用 .gdbinit 模板一键连 gdbstub——-x 加载模板，连上后核对架构与复位 PC。
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"
OUT="$DIR/output/02"

echo '===== 1. 启动冻结虚拟机（-s 开 1234 gdbstub，-S 冻结在复位向量）====='
start_qemu "$OUT"
echo "qemu pid=${QEMU_PID}，gdbstub 端口 ${GDPPORT} 已监听"

echo
echo '===== 2. 通过 -x 加载 .gdbinit 模板连接（不再手敲 set architecture/target remote）====='
run "$GDB" -q -nx -batch -x "$DIR/templates/qemu-riscv64.gdbinit" \
  -ex 'show architecture' \
  -ex 'info registers pc'

echo
echo '===== 3. 收掉虚拟机 ====='
stop_qemu
echo '实验 2 完成：模板把架构锁定与连接参数固化，连上即 riscv:rv64，PC=0x1000 复位向量。'
