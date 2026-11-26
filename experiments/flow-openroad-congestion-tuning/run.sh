#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
OR_BIN="${OR_BIN:-openroad}"
mkdir -p results
rm -f results/baseline.* results/tuned.*

run_round() {
  local tag="$1" density="$2"
  echo "# command: TAG=$tag DENSITY=$density openroad -exit -no_init scripts/route.tcl"
  TAG="$tag" DENSITY="$density" "$OR_BIN" -exit -no_init scripts/route.tcl 2>&1 | tee "results/$tag.log"
  sed -n '/Final congestion report:/,/Total wirelength:/p' "results/$tag.log" > "results/$tag.congestion-summary.rpt"
}

count_report_items() {
  local file="$1"
  grep -c '^violation type:' "$file" || true
}

congestion_total() {
  local file="$1" line value
  line="$(grep '^Total ' "$file")"
  for value in $line; do :; done
  printf '%s\n' "$value"
}

"$OR_BIN" -version
run_round baseline 0.95
run_round tuned 0.45

for tag in baseline tuned; do
  test -s "results/$tag.log"
  test -f "results/$tag.guide"
  test -s "results/$tag.congestion-summary.rpt"
  test -f "results/$tag.drc.rpt"
  grep -q "RUN_CONFIG tag=$tag" "results/$tag.log"
  grep -q "ROUTE_COMPLETE tag=$tag" "results/$tag.log"
done

baseline_congestion="$(congestion_total results/baseline.congestion-summary.rpt)"
tuned_congestion="$(congestion_total results/tuned.congestion-summary.rpt)"
baseline_drc="$(count_report_items results/baseline.drc.rpt)"
tuned_drc="$(count_report_items results/tuned.drc.rpt)"

printf 'ROUND_RESULT tag=baseline density=0.95 congestion=%s drc=%s\n' "$baseline_congestion" "$baseline_drc" | tee results/summary.rpt
printf 'ROUND_RESULT tag=tuned density=0.45 congestion=%s drc=%s\n' "$tuned_congestion" "$tuned_drc" | tee -a results/summary.rpt

if [ "$baseline_congestion" -gt "$tuned_congestion" ] \
  && [ "$tuned_congestion" -eq 0 ] \
  && [ "$tuned_drc" -lt "$baseline_drc" ]; then
  echo "RUN_RESULT EXPECT_MATCH baseline_congestion=$baseline_congestion tuned_congestion=$tuned_congestion baseline_drc=$baseline_drc tuned_drc=$tuned_drc" | tee -a results/summary.rpt
else
  echo "RUN_RESULT EXPECT_MISMATCH baseline_congestion=$baseline_congestion tuned_congestion=$tuned_congestion baseline_drc=$baseline_drc tuned_drc=$tuned_drc" >&2
  exit 1
fi
