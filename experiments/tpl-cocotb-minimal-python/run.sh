#!/usr/bin/env bash
# Reproduce all evidence for the cocotb minimal Python template article.
# Run inside the geek-eda container after activating the cocotb venv.
set -u
cd "$(dirname "$0")"

echo "=== run 1: normal suite, expect 3 passed ==="
make clean >/dev/null 2>&1 || true
timeout 60 make SIM=icarus
echo "NORMAL_RUN_EXIT=$?"

echo "=== run 2: unreachable edge hang, outer timeout kills it, expect 124 ==="
make clean >/dev/null 2>&1 || true
timeout 15 make SIM=icarus COCOTB_TEST_MODULES=hang
echo "HANG_RUN_EXIT=$? (expect 124)"

echo "=== run 3: filter matches no test, cocotb exits 0: the zero-test false green ==="
make clean >/dev/null 2>&1 || true
timeout 60 make SIM=icarus COCOTB_TEST_FILTER=does_not_exist
echo "EMPTY_RUN_EXIT=$? (0 even though no test ran; CI must parse the TESTS= line)"

make clean >/dev/null 2>&1 || true
echo "RUN_SH_DONE"
