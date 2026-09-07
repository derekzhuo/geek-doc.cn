#!/bin/bash
# 解析 phase52 结果：LT vs ET 对比
cd /root/echo-day04/results_split_v2 || exit 1
for f in 52-*.txt; do
  echo "== $f =="
  grep -E "^ QPS|^  P50|^  P99" "$f"
done
