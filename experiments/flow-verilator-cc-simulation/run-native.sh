#!/usr/bin/env bash
# 容器内（或本机 Verilator 环境）实际执行的三步
set -euo pipefail

rm -rf obj_dir wave.vcd
# 1) verilate：Verilog -> C++ 与 Makefile（不自动编译）
verilator --cc --exe --trace --top-module top top.v tb_top.cpp
# 2) make：g++ 编译 harness 与生成代码，链接出 Vtop
make -C obj_dir -f Vtop.mk Vtop
# 3) 运行：无波形快速判定
./obj_dir/Vtop
# 4) 带 --trace 再跑一次，产出 wave.vcd
./obj_dir/Vtop --trace
