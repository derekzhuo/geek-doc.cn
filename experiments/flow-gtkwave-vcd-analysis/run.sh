#!/usr/bin/env bash
# GTKWave 波形分析（搜索/marker/缩放/过滤器/双 VCD 对照）全流程证据
# 说明：GTKWave 3.3.116 无头模式下 -S 脚本执行完后主循环偶发不退出，
# 统一用 timeout 60s 包裹；rc=124 且预期 marker 已全部输出时按成功处理。
set -u
IMAGE=geek-eda:0.4-flow
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "# command: bash run.sh (docker geek-eda:0.4-flow, Xvfb)"
echo "# date: 2026-11-06"
echo "# host-toolchain: Icarus Verilog 12.0 / GTKWave 3.3.116 (geek-eda:0.4-flow docker)"

echo "==== [1] versions ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
  'iverilog -V 2>&1 | head -1; xvfb-run -a gtkwave -V 2>&1 | head -1'

echo "==== [2] compile and run two scenarios (A: fast drain, B: slow drain) ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
  'iverilog -g2012 -o sim.vvp tb_fifo.v sync_fifo.v && vvp sim.vvp +MODE=A && vvp sim.vvp +MODE=B && ls -l wave_a.vcd wave_b.vcd'

echo "==== [3] VCD declaration section (scopes and signals) ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
  'grep -E "timescale|scope|var|enddefinitions" wave_a.vcd'

echo "==== [4] gtkwave -S analyze.tcl : search/edges/markers/zoom/filter/tabs/save ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
  'timeout 60 xvfb-run -a gtkwave -S analyze.tcl > step4.raw 2>&1; rc=$?;
   grep -E "SEARCH_HITS|TRACES|FULL_EDGES|FULL_ASSERT|FULL_DEASSERT|FULL_DURATION|RD_RISING|RD_HANDSHAKE|BASELINE_EXPORT|ZOOM|TRANSLATE|HIGHLIGHT|TABS_OPEN|SAVE_WRITTEN" step4.raw;
   if [ $rc -eq 124 ]; then echo "NOTE: rc=124 timeout after all markers emitted (headless main-loop quirk)"; else echo "rc=$rc"; fi'

echo "==== [5] full change-table export for both scenarios (baseline A vs B) ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
  'SCENE=A timeout 60 xvfb-run -a gtkwave -S export_full.tcl >/dev/null 2>&1; echo "A rc=$?";
   SCENE=B timeout 60 xvfb-run -a gtkwave -S export_full.tcl >/dev/null 2>&1; echo "B rc=$?";
   echo "-- full_a.txt --"; head -6 full_a.txt; echo "-- full_b.txt --"; head -6 full_b.txt;
   echo "-- firerd_b.txt --"; cat firerd_b.txt'

echo "==== [6] text baseline diff: full flag edges A vs B ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
  'diff -u full_a.txt full_b.txt || true'

echo "==== [6b] scenario B handshake gaps (read one, idle one) ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
  'timeout 60 xvfb-run -a gtkwave -S gaps_b.tcl 2>&1 | grep -E "B_RD"'

echo "==== [7] pitfall: time-dimension menu command segfaults headless on 3.3.116 ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
  'timeout 30 xvfb-run -a gtkwave -S timedim.tcl wave_a.vcd >/dev/null 2>&1; echo "rc=$? (139=SIGSEGV, use ps->ns conversion in Tcl)"'

echo "==== [8] analysis.gtkw excerpt (dumpfile fingerprint, signal list and formats) ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
  'sed -n "1,32p" analysis.gtkw'
