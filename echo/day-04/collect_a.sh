#!/bin/bash
# 汇总 A 端 pps 与 tw 采集文件
DIR=/root/echo-day04/results_split_v2
for f in $DIR/pps-*.txt; do
  echo "== $(basename $f) =="
  awk '/eth0/{print $3, $5}' "$f"
done
echo ""
for f in $DIR/tw-*.txt; do
  echo "== $(basename $f) =="
  head -2 "$f"
  echo "..."
  tail -2 "$f"
done
