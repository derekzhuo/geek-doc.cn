#!/usr/bin/env bash
set -u

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LOG_PATH=${LOG_PATH:-"$ROOT/run1.log"}

exec > >(tee "$LOG_PATH") 2>&1
printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: OpenSTA 2.0.17 / Ubuntu 24.04\n'

sta -version
printf '\nCASE: missing cell\n'
sta -no_init -exit "$ROOT/missing_cell.tcl"
missing_status=$?
printf 'CASE_EXIT missing_cell=%s\n' "$missing_status"

printf '\nCASE: no library\n'
sta -no_init -exit "$ROOT/no_library.tcl"
no_library_status=$?
printf 'CASE_EXIT no_library=%s\n' "$no_library_status"

printf '\nCASE: fixed cell\n'
sta -no_init -exit "$ROOT/fixed.tcl"
fixed_status=$?
printf 'CASE_EXIT fixed=%s\n' "$fixed_status"

if [ "$fixed_status" -ne 0 ]; then
  exit 1
fi
