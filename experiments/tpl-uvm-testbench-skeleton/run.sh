#!/usr/bin/env bash
# 编译并运行简化 SV 骨架；INJECT_BUG=1 时向 DUT 注入 +1/+2 差异
set -u
cd "$(dirname "$0")"

verilator --binary --timing --timescale 1ns/1ns -j 2 -Wno-fatal \
  --top-module top \
  sim/dut_if.sv sim/dut.sv sim/tb_classes.sv sim/top.sv \
  -o Vtop

if [ "${INJECT_BUG:-0}" = "1" ]; then
  ./obj_dir/Vtop +inject_bug
else
  ./obj_dir/Vtop
fi
