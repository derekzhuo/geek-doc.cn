#!/bin/sh
# 复现 Verilator 4.x 的 STMTDLY 报错与修复验证
# 本机装有 verilator 4.x 时直接 sh run.sh；或走 docker：
#   docker run --rm -v "$PWD":/work -w /work verilator/verilator:4.038 sh run.sh
echo '== 1. 复现报错（blinky_delay.v 含 #10）=='
verilator --lint-only -Wall blinky_delay.v
echo "exit_code=$?"
echo
echo '== 2. 验证修复（blinky_fixed.v 可综合写法）=='
verilator --lint-only -Wall blinky_fixed.v
echo "exit_code=$?"
