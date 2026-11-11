#!/usr/bin/env bash
set -u
STA_BIN="${STA_BIN:-sta}"
for case_name in bad warn_empty fixed; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl" 2>&1
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$?"
done
