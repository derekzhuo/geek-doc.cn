#!/usr/bin/env bash
# 实验 2：第一个断点——复位向量 0x1000 起步，在 OpenSBI 入口 0x80000000 打断点、单步
# 对应教程：https://geek-doc.cn/soc-qemu/qemu-gdb-first-breakpoint.html
# 注意：全部动作放在同一个 gdb 会话里。gdb 退出时虚拟机恢复运行，重连后入口代码早已
# 执行过去，0x80000000 的断点不会再次命中，continue 会永久挂住。
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"

OUT="$DIR/output/02"
mkdir -p "$OUT"

echo '===== 1. 启动冻结虚拟机（-s -S），CPU 停在复位向量，一条指令都没跑 ====='
start_qemu "$OUT"
echo "qemu pid=${QEMU_PID}，gdbstub 端口 ${GDPPORT} 已监听"

echo
echo '===== 2. 单会话完成：看起点 PC → 0x80000000 下断点 → continue 命中 → 反汇编 → 单步两次 ====='
gdb_session \
  -ex 'info registers pc' \
  -ex 'break *0x80000000' \
  -ex 'continue' \
  -ex 'info registers pc' \
  -ex 'x/4i $pc' \
  -ex 'stepi' \
  -ex 'stepi' \
  -ex 'info registers pc'

echo
echo '===== 3. 收掉虚拟机 ====='
stop_qemu
echo '实验 2 完成：0x80000000 处是 OpenSBI 启动代码（保存 a0/a1/a2 后跳转初始化），单步每次前进 4 字节（RV64 指令定长）。'
