#!/bin/bash
# 汇总 B 端所有 bench 结果文件
DIR=/root/echo-day04/results_split_v2
for f in $DIR/ppsbench-*.txt; do
  echo "== $(basename $f) =="
  grep -E "^ QPS|^  P50|^  P99" "$f"
done
