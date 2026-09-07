#!/bin/bash
# 汇总所有实验结果，输出到标准输出供报告整理
DIR=/root/echo-day04/results_split_v2

echo "############ 长连接 PPS 对照场景 ############"
echo "--- bench ---"
grep -E "^ QPS|^  P50|^  P99" $DIR/ppsbench-pps-long-c1000.txt
echo "--- PPS (rxpck/s) ---"
awk '/eth0/{print $3, $5}' $DIR/pps-pps-long-c1000.txt
echo "--- TIME_WAIT 采样 ---"
head -3 $DIR/tw-pps-long-c1000.txt
tail -2 $DIR/tw-pps-long-c1000.txt
