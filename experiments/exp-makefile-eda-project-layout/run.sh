#!/usr/bin/env bash
# exp-makefile-eda-project-layout: template project make run + lint + clean
set -u
SLUG="exp-makefile-eda-project-layout"
OUT="${1:-/tmp/evidence/$SLUG}"
mkdir -p "$OUT"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec > >(tee "$OUT/run.log") 2>&1
set -x

WORK="$OUT/work"
mkdir -p "$WORK"
cp -r "$SRC_DIR/rtl" "$SRC_DIR/tb" "$SRC_DIR/Makefile" "$WORK/"
cd "$WORK"

echo "=== make run (iverilog compile + sim) ==="
make run 2>&1 | tee make_run.log

echo "=== make lint (verilator -Wall) ==="
make lint 2>&1 | tee make_lint.log || true   # lint warnings allowed, logged

echo "=== make clean ==="
make clean

if grep -q 'RESULT: PASS' make_run.log; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
