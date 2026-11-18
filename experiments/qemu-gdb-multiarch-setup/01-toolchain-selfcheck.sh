#!/usr/bin/env bash
# 实验 1：跨架构 gdb 环境自检——工具就位情况、单目标 gdb 支持的架构清单、
# 用错误架构名验证「为什么需要 gdb-multiarch / 目标专属 gdb」。
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=common.sh
source "$DIR/common.sh"

echo '===== 1. 工具就位：QEMU 与 RISC-V 交叉 gdb 的真实版本 ====='
run which "$QEMU"
run "$QEMU" --version
run which "$GDB"
run "$GDB" --version

echo
echo '===== 2. 单目标 gdb 的架构清单：只认识 RISC-V 三档加 auto ====='
run "$GDB" -q -nx -batch -ex 'set architecture'

echo
echo '===== 3. 阴性反例：让 RISC-V 专属 gdb 切到 i386，直接被拒 ====='
echo '（Linux 上 gdb-multiarch 一份 gdb 内置全部后端；专属 gdb 没有外来架构后端）'
run "$GDB" -q -nx -batch -ex 'set architecture i386' || true

echo
echo '实验 1 完成：专属 gdb 只能调试编译时绑定的目标架构，跨架构调试要装 gdb-multiarch 或对应专属 gdb。'
