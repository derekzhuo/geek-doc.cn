#!/usr/bin/env bash
# 全流程：iverilog 产 VCD -> gtkwave tcl 批处理（加信号/导数据/写 save）
# -> 命令行加载后即退出（-x）-> 输出重定向（-O）-> 用 save 文件恢复布局后即退出
set -u
IMAGE=geek-eda:0.3-sta
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "# command: bash run.sh"
echo "# date: 2026-11-03"
echo "# host-toolchain: Icarus Verilog 12.0 / GTKWave 3.3.116 (geek-eda:0.3-sta docker, Xvfb)"

echo "==== [1] versions ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c 'iverilog -V 2>&1 | head -1; xvfb-run -a gtkwave -V 2>&1 | head -1'

echo "==== [2] compile and run simulation ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
    'iverilog -g2012 -o sim.vvp tb_counter.v counter.v && vvp sim.vvp && ls -l wave.vcd'

echo "==== [3] VCD head (declaration section) ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
    'sed -n "1,20p" wave.vcd'

echo "==== [4] gtkwave -S export.tcl : batch add signals / export data / write save ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
    'xvfb-run -a gtkwave -S export.tcl wave.vcd 2>&1 | grep -E "Executing|DISPLAYED|TOTAL_TRACES|FACS_EXPORTED|CNT_CHANGES|SAVE_WRITTEN|Filename|Exiting"'

echo "==== [5] exported facs.txt ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c 'cat facs.txt'

echo "==== [6] exported cnt_changes.txt (first 8 lines) ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c 'sed -n "1,8p" cnt_changes.txt; echo "..."; wc -l cnt_changes.txt'

echo "==== [7] layout.gtkw (save file text) ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c 'cat layout.gtkw'

echo "==== [8] -x exit after loading trace (loader smoke test), -O redirect output ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
    'xvfb-run -a gtkwave -x -O load.out wave.vcd >/dev/null 2>&1; echo "exit=$?"; cat load.out'

echo "==== [9] restore layout from save file noninteractively, then exit ===="
docker run --rm -v "$HERE":/work -w /work "$IMAGE" bash -c \
    'xvfb-run -a gtkwave -x -a layout.gtkw wave.vcd 2>&1 | grep -E "start time|end time|Executing|error|Error" ; echo "exit=$?"'
