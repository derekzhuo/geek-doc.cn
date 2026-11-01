#!/usr/bin/env bash
set -u
STA_BIN="${STA_BIN:-sta}"
for case_name in no_clock typo_hier wrong_port fixed; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl"
  rc=$?
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$rc"
done
