#!/usr/bin/env bash
set -u
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT" || exit 1
LOG_PATH=${LOG_PATH:-"$ROOT/run1.log"}
exec > >(tee "$LOG_PATH") 2>&1
printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: OpenSTA 2.0.17 / Ubuntu 24.04\n'
sta -version
for case_name in violation pass; do
  printf '\nCASE: %s\n' "$case_name"
  SDC_FILE="$case_name.sdc" sta -no_init -exit check.tcl
  status=$?
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$status"
done
