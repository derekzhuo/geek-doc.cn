#!/usr/bin/env bash
set -euo pipefail
STA_BIN="${STA_BIN:-sta}"
mkdir -p results

echo "# command: bash -x run.sh"
echo "# date: 2026-11-22"
echo "# assumptions: teaching.lib scalar delays; hypothetical board parameters"
"$STA_BIN" -version

for stage in baseline dual_edge; do
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

python3 summarize.py results results/summary.txt
cat results/summary.txt
