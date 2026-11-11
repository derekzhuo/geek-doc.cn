#!/usr/bin/env bash
set -u
STA_BIN="${STA_BIN:-sta}"
for case_name in diag case1_noclock case2_wrongobj case3_namemismatch fixed; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl" 2>&1
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$?"
done
