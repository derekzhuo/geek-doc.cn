#!/usr/bin/env bash
# 容器内冒烟：iverilog 编译执行 + verilator lint + yosys 综合，三件套各跑一次
set -euo pipefail

echo "== iverilog 编译并执行 =="
iverilog -g2012 -o hello.vvp hello.v tb_hello.v
vvp hello.vvp

echo "== verilator lint =="
verilator --lint-only -Wall hello.v

echo "== yosys 综合 =="
yosys -p "read_verilog hello.v; synth -top hello; stat"

echo "SMOKE PASS"
