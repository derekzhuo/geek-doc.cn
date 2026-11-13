#!/usr/bin/env bash
# Yosys 入门综合：同一份 4 位计数器 RTL，经过 read_verilog -> synth -> stat，
# 导出由通用单元（DFF、加法器、多路器）构成的网表，展示「综合把 RTL 变成了什么」。
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build

echo '$ bash run.sh'
echo "== 工具版本 =="
yosys -V
echo

echo "== 1. 执行综合脚本 synth.ys（read_verilog / synth / stat / write_verilog）=="
yosys -s synth.ys
echo

echo "== 2. 综合后网表 build/counter_netlist.v =="
cat build/counter_netlist.v
echo

echo "== 3. 网表中的通用单元统计 =="
grep -oE '\$[A-Za-z_0-9]+' build/counter_netlist.v | sort | uniq -c || true
echo "done"
