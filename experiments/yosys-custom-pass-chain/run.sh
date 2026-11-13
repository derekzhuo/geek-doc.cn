#!/usr/bin/env bash
# Yosys 手工 pass 链 vs synth 宏三方对照：
#   1) synth_macro.ys  —— synth 宏基线，一条命令跑默认 pass 序列；
#   2) manual_naive.ys —— 凭直觉展开的朴素手工链，缺关键化简 pass；
#   3) manual_full.ys  —— 按宏的真实 pass 序列镜像、并在四个阶段插 stat 的完整手工链。
# 同一份带 FSM 与计数器的 RTL，比较三条链的逐阶段 cell 数与终态面积。
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build

echo '$ bash run.sh'
echo "== 0. 工具版本 =="
yosys -V
echo

echo "== 1. synth 宏基线 =="
yosys -s synth_macro.ys 2>&1 | tee build/macro.log
echo

echo "== 2. 朴素手工链（缺 wreduce/peepopt/alumacc/share/abc/opt_clean）=="
yosys -s manual_naive.ys 2>&1 | tee build/naive.log
echo

echo "== 3. 镜像完整手工链（四段 stat 逐步留痕）=="
yosys -s manual_full.ys 2>&1 | tee build/full.log
echo

echo "== 4. 三条链终态 cell 数对照 =="
macro_cells=$(grep 'Number of cells:' build/macro.log | tail -1 | awk '{print $4}')
naive_cells=$(grep 'Number of cells:' build/naive.log | tail -1 | awk '{print $4}')
full_cells=$(grep 'Number of cells:' build/full.log | tail -1 | awk '{print $4}')
echo "synth 宏终态 cells      : ${macro_cells}"
echo "朴素手工链终态 cells    : ${naive_cells}"
echo "镜像完整手工链终态 cells: ${full_cells}"
echo

echo "== 5. 镜像链四次 stat 的 cell 数变化（proc/fsm/memory/techmap 四阶段）=="
grep 'Number of cells:' build/full.log | awk '{print NR": "$0}'
echo

echo "== 6. synth 宏实际执行的 pass 序列（朴素链缺哪些一目了然）=="
grep -E '^\s+[0-9]+\.[0-9]+\. Executing' build/macro.log | sed 's/^ *//' | head -30
echo "done"
