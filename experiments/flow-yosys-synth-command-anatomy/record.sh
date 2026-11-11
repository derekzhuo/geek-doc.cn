#!/bin/sh
# 容器内录制：版本 / help synth / 整跑 / -run 分段 / 手工展开 / 网表产物
set -e

echo '### 0. yosys version'
yosys -V

echo '### 1. help synth (macro expands to these commands)'
yosys -p 'help synth'

echo '### 2. run whole macro: read_verilog; synth -top demo; stat; check'
yosys -p 'read_verilog demo.v; synth -top demo; stat; check'

echo '### 3. run macro in pieces via -run labels (stages.ys)'
yosys stages.ys

echo '### 4. run the expanded command list by hand (manual.ys)'
yosys manual.ys

echo '### 5. write gate-level netlist and show its head'
yosys -p 'read_verilog demo.v; synth -top demo; write_verilog -noattr demo_netlist.v'
echo '--- demo_netlist.v head ---'
sed -n '1,22p' demo_netlist.v
echo '--- structural elements in netlist (assign gates / posedge always for FFs) ---'
printf 'assign lines: '; grep -c 'assign' demo_netlist.v
printf 'posedge always blocks: '; grep -c 'always @(posedge' demo_netlist.v
