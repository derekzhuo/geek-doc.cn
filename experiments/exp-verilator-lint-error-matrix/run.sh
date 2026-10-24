#!/usr/bin/env bash
# exp-verilator-lint-error-matrix: collect 9 typical verilator lint findings.
# Each file is EXPECTED to make verilator unhappy; non-zero exit is the point.
set -u
SLUG="exp-verilator-lint-error-matrix"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

cd "$OUT"

collected=0
for f in width caseincomplete unoptflat blkseq unused undriven latch multidriven implicit; do
    echo "================ lint case: $f.v ================"
    verilator --lint-only -Wall "$SRC_DIR/$f.v" 2>&1 | tee "lint_$f.log"
    rc=${PIPESTATUS[0]}
    echo "verilator exit code for $f.v: $rc (non-zero expected)"
    if grep -qE '%(Warning|Error)' "lint_$f.log"; then
        echo "COLLECTED: $f"
        collected=$((collected + 1))
    else
        echo "NOT-COLLECTED: $f (no warning/error text captured)"
    fi
done

echo "collected $collected of 9 lint findings"
if [ "$collected" -ge 8 ]; then
    echo "RESULT: COLLECTED"
else
    echo "RESULT: FAIL"
fi
