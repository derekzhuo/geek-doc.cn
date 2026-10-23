#!/bin/sh
# 复现 Verilator UNOPTFLAT 告警与打拍拆环修复（本机有 verilator 时直接跑）
set -x
verilator --version
verilator --lint-only -Wall loop_bad.v   # 预期：%Warning-UNOPTFLAT，exit 1
echo "bad exit: $?"
verilator --lint-only -Wall loop_fix.v   # 预期：无输出，exit 0
echo "fix exit: $?"
