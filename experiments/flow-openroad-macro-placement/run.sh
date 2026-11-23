#!/usr/bin/env bash
# OpenROAD 26Q4 宏单元摆放实验：三个流程依次执行，结果写入 results/
set -euo pipefail
OR_BIN="${OR_BIN:-openroad}"
mkdir -p results

echo "# command: bash run.sh"
echo "# date: 2026-11-23"
"$OR_BIN" -version

run_stage() {
  local name="$1"; shift
  echo "# command: $*"
  "$@" 2>&1 | tee "results/${name}.log"
}

run_stage 01_def_macro_place   "$OR_BIN" -no_init -exit scripts/01_def_macro_place.tcl
run_stage 02_floorplan_init    "$OR_BIN" -no_init -exit scripts/02_floorplan_init.tcl
run_stage 03_gp_nohalo env GP_MODE=nohalo "$OR_BIN" -no_init -exit scripts/03_gp_halo_compare.tcl
run_stage 03_gp_halo   env GP_MODE=halo   "$OR_BIN" -no_init -exit scripts/03_gp_halo_compare.tcl

for f in FLOW_01_OK FLOW_02_OK FLOW_03_OK; do
  if ! grep -q "$f" results/*.log; then echo "MARKER_MISSING $f" >&2; exit 1; fi
done

no_halo_line=$(grep '^GP_RESULT mode=nohalo' results/03_gp_nohalo.log)
halo_line=$(grep '^GP_RESULT mode=halo' results/03_gp_halo.log)
no_halo_band=$(echo "$no_halo_line" | sed 's/.*in_halo_band=\([0-9]*\).*/\1/')
halo_band=$(echo "$halo_line" | sed 's/.*in_halo_band=\([0-9]*\).*/\1/')
halo_body=$(echo "$halo_line" | sed 's/.*in_macro_body=\([0-9]*\).*/\1/')
echo "EXPECT_CHECK nohalo_band=$no_halo_band halo_band=$halo_band halo_body=$halo_body"
if [ "$halo_band" -lt "$no_halo_band" ] && [ "$halo_body" -eq 0 ]; then
  echo "RUN_RESULT EXPECT_MATCH"
  exit 0
fi
echo "RUN_RESULT EXPECT_MISMATCH" >&2
exit 1
