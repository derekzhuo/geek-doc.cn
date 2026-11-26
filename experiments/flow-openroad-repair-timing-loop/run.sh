#!/usr/bin/env bash
# OpenROAD 26Q4 时序修复闭环实验：基线 -> setup 迭代修复 -> hold 修复，日志写入 results/
set -euo pipefail
OR_BIN="${OR_BIN:-openroad}"
mkdir -p results

echo "# command: bash run.sh"
echo "# date: $(TZ=Asia/Shanghai date +%F)"
"$OR_BIN" -version

run_stage() {
  local name="$1"; shift
  echo "# command: $*"
  "$@" 2>&1 | tee "results/${name}.log"
}

run_stage 01_baseline      "$OR_BIN" -no_init -exit scripts/01_baseline.tcl
run_stage 02_setup_repair  "$OR_BIN" -no_init -exit scripts/02_setup_repair.tcl
run_stage 03_hold_repair   "$OR_BIN" -no_init -exit scripts/03_hold_repair.tcl

for f in FLOW_01_OK FLOW_02_OK FLOW_03_OK; do
  if ! grep -q "$f" results/*.log; then echo "MARKER_MISSING $f" >&2; exit 1; fi
done

# 收敛判据：最终 setup 与 hold 的 WNS 必须同时转正，TNS 归零
final=$(grep '^SLAP round=h1' results/03_hold_repair.log)
echo "FINAL_SNAP $final"
setup_wns=$(echo "$final" | sed 's/.*setup_wns=\(-*[0-9.]*\).*/\1/')
hold_wns=$(echo "$final" | sed 's/.*hold_wns=\(-*[0-9.]*\).*/\1/')
setup_tns=$(echo "$final" | sed 's/.*setup_tns=\(-*[0-9.]*\).*/\1/')
hold_tns=$(echo "$final" | sed 's/.*hold_tns=\(-*[0-9.]*\).*/\1/')
echo "EXPECT_CHECK setup_wns=$setup_wns hold_wns=$hold_wns setup_tns=$setup_tns hold_tns=$hold_tns"
awk -v a="$setup_wns" -v b="$hold_wns" -v c="$setup_tns" -v d="$hold_tns" \
  'BEGIN { if (a > 0 && b > 0 && c == 0 && d == 0) exit 0; else exit 1 }' \
  && { echo "RUN_RESULT EXPECT_MATCH"; exit 0; }
echo "RUN_RESULT EXPECT_MISMATCH" >&2
exit 1
