#!/usr/bin/env bash
# Run every lab in order and require RESULT: PASS from each one.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
passed=0
for d in lab*/; do
  lab="${d%/}"
  out=$(make "$lab" 2>&1)
  rc=$?
  echo "$out"
  if [ $rc -ne 0 ] || ! echo "$out" | grep -q "RESULT: PASS"; then
    fail=1
  else
    passed=$((passed + 1))
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "RESULT: PASS ${passed}/5"
else
  echo "RESULT: FAIL (${passed}/5 passed)"
fi
exit "$fail"
