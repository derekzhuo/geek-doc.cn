#!/usr/bin/env bash
# 三个错误场景（根因 1 建错网络 / 根因 2 缓冲弧断传 / 根因 3 SDC 未生效：未 source 与过早 source）+ 修复
set -u
STA_BIN="${STA_BIN:-sta}"
for case_name in case1_wrong_net case2_broken_buf case3_nosource case3b_early_source fixed; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl" 2>&1
  rc=$?
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$rc"
done
