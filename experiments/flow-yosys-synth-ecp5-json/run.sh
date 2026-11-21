#!/usr/bin/env bash
set -euo pipefail
mkdir -p build results

yosys -V | tee build/version.log
yosys -s ice40.ys 2>&1 | tee build/ice40.log
yosys -s ecp5.ys 2>&1 | tee build/ecp5.log
if yosys -s early-fail.ys >build/early-fail.log 2>&1; then
    echo "expected early JSON export to fail, but it succeeded" >&2
    exit 1
else
    cat build/early-fail.log
fi
yosys -s early.ys 2>&1 | tee build/early.log
yosys -s readback.ys 2>&1 | tee build/readback.log
python3 inspect_json.py | tee build/summary.log
cp build/summary.log results/summary.log
