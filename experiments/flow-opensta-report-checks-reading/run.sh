#!/usr/bin/env bash
# 三个场景：met（2.0ns 周期 setup met）、fast（0.5ns 周期 setup violated）、
# latency（0.20ns 时钟网络延迟，观察 latency 字段，slack 不变）
set -u
STA_BIN="${STA_BIN:-sta}"
"$STA_BIN" -version
for case_name in met fast latency; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl" 2>&1
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$?"
done
