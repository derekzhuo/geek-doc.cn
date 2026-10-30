#!/usr/bin/env bash
set -u
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT" || exit 1
LOG_PATH=${LOG_PATH:-"$ROOT/run1.log"}
exec > >(tee "$LOG_PATH") 2>&1
printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: OpenSTA 2.0.17 / Ubuntu 24.04\n'
STA_BIN="${STA_BIN:-sta}"
for case_name in compat violation relaxed; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl"
  rc=$?
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$rc"
done
