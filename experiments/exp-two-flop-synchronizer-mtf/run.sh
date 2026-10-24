#!/usr/bin/env bash
# exp-two-flop-synchronizer-mtf: 2-FF synchronizer follow-up latency check + VCD
set -u
SLUG="exp-two-flop-synchronizer-mtf"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cd "$WORK"

iverilog -g2012 -o sim.vvp "$SRC_DIR/sync_2ff.v" "$SRC_DIR/tb_sync_2ff.v"
vvp sim.vvp | tee sim.log
ls -l sync_2ff.vcd
cp -f sync_2ff.vcd "$OUT/" 2>/dev/null || true

if grep -q 'RESULT: PASS' sim.log; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
