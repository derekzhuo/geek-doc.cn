#!/usr/bin/env bash
set -euo pipefail
STA_BIN="${STA_BIN:-sta}"
IVERILOG_BIN="${IVERILOG_BIN:-iverilog}"
VVP_BIN="${VVP_BIN:-vvp}"
mkdir -p results

echo "# command: bash run.sh"
echo "# date: 2026-11-22"
"$STA_BIN" -version

{
  echo "# command: bash run.sh (protocol)"
  "$IVERILOG_BIN" -g2012 -o results/.protocol_sim sim_cells.v top.v protocol_tb.v
  "$VVP_BIN" results/.protocol_sim
  rm -f results/.protocol_sim
  echo "STAGE_EXIT protocol=0"
} 2>&1 | tee results/protocol.log

for stage in baseline false_path multicycle; do
  {
    echo "# command: bash run.sh ($stage)"
    echo "# design: top.v; clock: 0.60 ns; library: teaching.lib"
    "$STA_BIN" -no_init -exit "${stage}.tcl" 2>&1
    echo "STAGE_EXIT ${stage}=0"
  } | tee "results/${stage}.log"
done

python3 summarize.py results results/summary.txt
cat results/summary.txt
