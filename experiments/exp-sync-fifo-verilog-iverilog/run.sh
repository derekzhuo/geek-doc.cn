#!/usr/bin/env bash
# exp-sync-fifo-verilog-iverilog: sync FIFO regression (fill/drain/random/wrap)
set -u
SLUG="exp-sync-fifo-verilog-iverilog"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

iverilog -g2012 -o sim.vvp "$SRC_DIR/sync_fifo.v" "$SRC_DIR/tb_sync_fifo.v"
vvp sim.vvp | tee sim.log
cp -f sync_fifo.vcd "$OUT/" 2>/dev/null || true

if grep -q 'RESULT: PASS' sim.log; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
