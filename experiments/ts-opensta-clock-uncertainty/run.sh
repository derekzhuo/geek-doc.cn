#!/usr/bin/env bash
# 五个失效/误用场景（时钟名拼错 / 顺序颠倒 / rise-fall 误用与 setup-hold 作用域 /
# 同作用域覆盖 / 数值过大）+ 修复
set -u
STA_BIN="${STA_BIN:-sta}"
for case_name in bad_name order scope override big_unc fixed; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl" 2>&1
  rc=$?
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$rc"
done
