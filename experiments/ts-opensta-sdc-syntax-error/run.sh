#!/usr/bin/env bash
# 依次触发 6 类 SDC 错误用例，再跑修复用例；合并 stdout/stderr，记录各组退出码。
set -u
STA_BIN="${STA_BIN:-sta}"
for case_name in e1_typo e2_no_period e3_brace e4_empty e5_unit e6_waveform fixed; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl" 2>&1
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$?"
done
