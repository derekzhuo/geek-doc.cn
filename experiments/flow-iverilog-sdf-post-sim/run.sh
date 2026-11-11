#!/usr/bin/env bash
# 一条命令走完：Yosys 综合 -> 生成最小 SDF -> iverilog 前仿 -> iverilog 门级后仿
set -eu
cd "$(dirname "$0")"
IMG=geek-eda:0.3-sta
DRUN="docker run --rm -v $PWD:/work -w /work ${IMG}"

echo "# command: make run (bash run.sh) in experiments/flow-iverilog-sdf-post-sim"
echo "# date: 2026-11-03"
echo "# host-toolchain: Yosys 0.33 + Icarus Verilog 12.0 (geek-eda:0.3-sta docker)"

echo "==== versions ===="
${DRUN} yosys -V
${DRUN} iverilog -V | head -2

echo "==== 1) synthesis: RTL -> generic gate netlist ===="
${DRUN} yosys -s synth.ys

echo "==== 2) cell instances in netlist.v ===="
${DRUN} bash -c "grep -oE '\\\$_[A-Z0-9_]+_' netlist.v | sort | uniq -c"

echo "==== 3) generate teaching SDF from netlist ===="
${DRUN} bash -c "awk -f gen_sdf.awk netlist.v > counter.sdf && grep -c CELL counter.sdf"
${DRUN} bash -c "sed -n '1,12p' counter.sdf"

echo "==== 4) RTL pre-layout simulation (zero delay) ===="
${DRUN} bash -c "iverilog -o pre.vvp counter.v tb_counter.v && vvp pre.vvp"

echo "==== 5) gate-level post-synthesis simulation with SDF back-annotation ===="
${DRUN} bash -c "iverilog -g2012 -gspecify -DGATES -o gate.vvp gates_sim.v netlist.v tb_counter.v && vvp gate.vvp"

echo "==== done ===="
