#!/bin/bash
# 解析 phase53 结果：连接数扫描
cd /root/echo-day04/results_split_v2 || exit 1
for f in 53-*.txt; do
  echo "== $f =="
  grep -E "^ QPS|^  P50|^  P99" "$f"
done
