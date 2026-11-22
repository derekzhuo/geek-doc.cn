#!/usr/bin/env bash
set -euo pipefail
STA_BIN="${STA_BIN:-sta}"
mkdir -p results

echo "# command: bash run.sh"
echo "# date: 2026-11-23"
"$STA_BIN" -version

for stage in pass fail; do
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

# sta itself returns 0 even on VIOLATED; map the QOR_GATE line to a shell status.
pass_gate=$(grep '^QOR_GATE' results/pass.log | sed 's/.*overall=\([A-Z]*\).*/\1/')
fail_gate=$(grep '^QOR_GATE' results/fail.log | sed 's/.*overall=\([A-Z]*\).*/\1/')
echo "EXPECT_CHECK pass=$pass_gate fail=$fail_gate"
if [ "$pass_gate" = PASS ] && [ "$fail_gate" = FAIL ]; then
  echo "RUN_RESULT EXPECT_MATCH"
  exit 0
fi
echo "RUN_RESULT EXPECT_MISMATCH" >&2
exit 1
