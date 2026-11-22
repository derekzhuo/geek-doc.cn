#!/usr/bin/env bash
set -euo pipefail
STA_BIN="${STA_BIN:-sta}"
mkdir -p results

echo "# command: bash run.sh"
echo "# date: 2026-11-23"
"$STA_BIN" -version

for stage in nogen gen; do
  {
    echo "# command: sta -no_init -exit ${stage}.tcl"
    "$STA_BIN" -no_init -exit "${stage}.tcl" 2>&1
    echo "STAGE_EXIT ${stage}=0"
  } | tee "results/${stage}.log"
  if grep -q '^Error:' "results/${stage}.log"; then
    echo "STA_ERROR ${stage}" >&2
    exit 1
  fi
done

# 版本一必须暴露无时钟引脚与无约束端点；版本二必须出现 clk_div2 路径组且无 unclocked 告警。
nogen_unclocked=$(grep -c 'unclocked register/latch pin' results/nogen.log || true)
gen_unclocked=$(grep -c 'unclocked register/latch pin' results/gen.log || true)
gen_group=$(grep -c 'Path Group: clk_div2' results/gen.log || true)
echo "EXPECT_CHECK nogen_unclocked=${nogen_unclocked} gen_unclocked=${gen_unclocked} gen_div2_paths=${gen_group}"
if [ "$nogen_unclocked" -ge 1 ] && [ "$gen_unclocked" -eq 0 ] && [ "$gen_group" -ge 1 ]; then
  echo "RUN_RESULT EXPECT_MATCH"
  exit 0
fi
echo "RUN_RESULT EXPECT_MISMATCH" >&2
exit 1
