#!/usr/bin/env bash
# 分三个独立 sta 进程演示 SDC 的正确编写顺序：
# 阶段 1 只建时钟；阶段 2 补 IO 边界；阶段 3 加 false_path/multicycle/clock_groups 例外。
set -u
STA_BIN="${STA_BIN:-sta}"

echo "# command: bash run.sh (sta -no_init -exit stage1.tcl stage2.tcl stage3.tcl)"
echo "# date: 2026-11-03"
echo "# host-toolchain: OpenSTA 2.0.17 (geek-eda:0.3-sta docker)"
"$STA_BIN" -version | head -1

for stage in stage1 stage2 stage3 stage4; do
  printf '\n########## %s ##########\n' "$stage"
  "$STA_BIN" -no_init -exit "${stage}.tcl" 2>&1
  printf 'STAGE_EXIT %s=%s\n' "$stage" "$?"
done
