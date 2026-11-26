#!/usr/bin/env bash
set -euo pipefail
OR_BIN="${OR_BIN:-openroad}"
mkdir -p results
rm -f results/01_place_estimate.log results/02_route_extract.log results/03_readback.log
rm -f results/01_placed.def results/02_global_route.guide results/02_global_route.spef

run_stage() {
  local name="$1"; shift
  echo "# command: $*"
  "$@" 2>&1 | tee "results/${name}.log"
}

echo "# command: bash run.sh"
echo "# date: $(TZ=Asia/Shanghai date +%F)"
"$OR_BIN" -version
run_stage 00_probe         "$OR_BIN" -no_init -exit scripts/00_probe.tcl
run_stage 01_place_estimate "$OR_BIN" -no_init -exit scripts/01_place_estimate.tcl
run_stage 02_route_extract  "$OR_BIN" -no_init -exit scripts/02_route_extract.tcl
run_stage 03_readback       "$OR_BIN" -no_init -exit scripts/03_readback.tcl

for marker in STAGE_00_API_PROBE_OK STAGE_01_PLACEMENT_OK STAGE_02_GLOBAL_ROUTE_SPEF_OK STAGE_03_SPEF_READBACK_OK; do
  grep -q "$marker" results/*.log
 done
for output in results/01_placed.def results/02_global_route.guide results/02_global_route.spef; do
  test -s "$output"
done
python3 verify.py | tee results/verify.log
echo "RUN_RESULT PASS"
