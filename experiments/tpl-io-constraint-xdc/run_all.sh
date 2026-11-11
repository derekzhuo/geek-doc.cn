#!/bin/sh
# 容器内总控：综合 -> 正确 XDC -> 错误 XDC -> 修正后重跑
set -x
yosys -q synth.ys -l synth.log
grep -E 'Number of cells:' synth.log | tail -2
sta -no_init -exit run_sta.tcl
sta -no_init -exit run_sta_bad.tcl
sta -no_init -exit run_sta.tcl
