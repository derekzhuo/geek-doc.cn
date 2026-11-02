#!/usr/bin/env bash
# 闭环演示：违例网表 STA -> 放松周期复跑 -> RTL 插流水级重新综合后复跑
set -u
STA_BIN="${STA_BIN:-sta}"
YOSYS_BIN="${YOSYS_BIN:-yosys}"
mkdir -p build

"$STA_BIN" -version
"$YOSYS_BIN" -V

for variant in top_bad top_fix; do
  printf '\n===== synth %s =====\n' "$variant"
  sed "s/@V@/$variant/g" synth.ys > "build/synth_$variant.ys"
  "$YOSYS_BIN" -s "build/synth_$variant.ys"
  printf 'YOSYS_EXIT %s=%s\n' "$variant" "$?"
done

for case_name in bad relaxed fix; do
  printf '\n===== sta %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl" 2>&1
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$?"
done
