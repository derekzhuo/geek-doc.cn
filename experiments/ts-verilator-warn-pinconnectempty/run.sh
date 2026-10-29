#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

printf '%s\n' '# command: ./run.sh'
printf '%s\n' '# date: 2026-10-30'
printf '%s\n' '# host-toolchain: Docker geek-eda:0.2 / Verilator 5.020 2024-01-01 rev (Debian 5.020-1)'
printf '%s\n' '$ docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 verilator --lint-only -Wall --top-module top_bad child.v top_bad.v'
broken_status=0
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 \
  verilator --lint-only -Wall --top-module top_bad child.v top_bad.v || broken_status=$?
printf '# broken_exit_code: %s\n' "$broken_status"

printf '%s\n' '$ docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 verilator --lint-only -Wall --top-module top_fixed child.v top_fixed.v'
fixed_status=0
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 \
  verilator --lint-only -Wall --top-module top_fixed child.v top_fixed.v || fixed_status=$?
printf '# fixed_exit_code: %s\n' "$fixed_status"

if [ "$broken_status" -ne 0 ] && [ "$fixed_status" -eq 0 ]; then
  printf '%s\n' 'PASS: PINCONNECTEMPTY reproduced; named unused signal fixes lint'
  exit 0
fi

printf '%s\n' 'FAIL: expected broken lint to fail and fixed lint to pass'
exit 1
