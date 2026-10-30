#!/usr/bin/env bash
set -u
STA_BIN="${STA_BIN:-sta}"
for case_name in wrong_instance wrong_design fixed; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl" 2>&1
  rc=$?
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$rc"
done
