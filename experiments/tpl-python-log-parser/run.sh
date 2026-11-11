#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
trap 'rm -rf __pycache__' EXIT

printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: %s-%s / %s\n' \
  "$(uname -s)" "$(uname -m)" "$(python3 --version 2>&1)"

python3 -m py_compile parse_sim_log.py
compile_status=$?
printf 'PY_COMPILE_EXIT=%s\n' "$compile_status"

python3 parse_sim_log.py sample_sim.log
sample_status=$?
printf 'SAMPLE_PARSE_EXIT=%s\n' "$sample_status"

python3 parse_sim_log.py --fail-on-test sample_sim.log >/dev/null
ci_status=$?
printf 'FAIL_ON_TEST_EXIT=%s (expected 1)\n' "$ci_status"

python3 parse_sim_log.py malformed.log
malformed_status=$?
printf 'MALFORMED_INPUT_EXIT=%s (expected 2)\n' "$malformed_status"

python3 parse_sim_log.py missing.log
missing_status=$?
printf 'MISSING_INPUT_EXIT=%s (expected 2)\n' "$missing_status"

if [[ "$compile_status" -eq 0 && "$sample_status" -eq 0 && \
      "$ci_status" -eq 1 && "$malformed_status" -eq 2 && \
      "$missing_status" -eq 2 ]]; then
  printf 'RUN_SH_RESULT=PASS\n'
  exit 0
fi
printf 'RUN_SH_RESULT=FAIL\n'
exit 1
