#!/usr/bin/env bash
# 同一计数器设计两种模式对照：A = verilator --binary（Verilog TB，自动 main）
#                            B = verilator --cc （只生成 C++，手写 harness，自己 make）
set -euxo pipefail

echo "# command: bash run.sh (geek-eda:0.3-sta container, workdir /work)"
echo "# date: 2026-11-03"
echo "# host-toolchain: Verilator 5.020 (geek-eda:0.3-sta docker)"

verilator --version

echo "===== MODE A: verilator --binary (Verilog TB, auto-generated main) ====="
verilator --binary --timing -j 0 -Wall --top-module tb_counter \
    --Mdir obj_dir_bin counter.v tb_counter.v
echo "--- obj_dir_bin 里与自动 main 相关的产物 ---"
ls obj_dir_bin | grep -E 'main|^Vtb_counter$' || true
echo "--- 自动生成 main 的证据：Vtb_counter__main.cpp 里的入口函数 ---"
grep -n "int main" obj_dir_bin/Vtb_counter__main.cpp || true
echo "--- 直接运行可执行文件 ---"
./obj_dir_bin/Vtb_counter

echo "===== MODE B: verilator --cc (RTL only + hand-written C++ harness) ====="
verilator --cc counter.v --exe tb_main.cpp --Mdir obj_dir_cc
echo "--- 只 --cc 不 --build：obj_dir_cc 产物清单（注意此时没有可执行文件）---"
ls obj_dir_cc
if [ ! -e obj_dir_cc/Vcounter ]; then
    echo "NOTE: Vcounter not built yet; --cc only generates C++ and a Makefile"
fi
echo "--- 第二步：自己调 make 完成 g++ 编译 ---"
make -C obj_dir_cc -f Vcounter.mk "-j$(nproc)" Vcounter
echo "--- 运行手工构建出的可执行文件 ---"
./obj_dir_cc/Vcounter

echo "===== 帮助原文：--build-jobs 与 --top-module ====="
verilator --help | grep -E 'build-jobs|top-module' | head -6 || true

echo "ALL DONE"
