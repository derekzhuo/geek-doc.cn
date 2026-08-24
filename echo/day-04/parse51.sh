#!/bin/bash
# 解析 phase51 结果：输出每档 3 轮的 QPS/P50/P99 用于取中位数
cd /root/echo-day04/results_split_v2 || exit 1
for f in 51-t*.txt; do
  echo "== $f =="
  grep -E "^ QPS|^  P50|^  P99|^  P999" "$f"
done
