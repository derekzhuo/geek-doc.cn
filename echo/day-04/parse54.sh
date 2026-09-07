#!/bin/bash
# 汇总 phase54 CPU 利用率数据
echo '===== 服务端A pidstat（echo-mt-server）====='
for n in 1 4 8 16; do
  echo "--- t$n ---"
  grep Average /root/echo-day04/results_split_v2/cpu-t$n.txt
done
echo ''
echo '===== 客户端B mpstat（所有CPU平均）====='
for n in 1 4 8 16; do
  echo "--- t$n ---"
  ssh -o BatchMode=yes root@10.206.0.2 "grep 'Average.*all' /root/echo-day04/results_split_v2/mp-t$n.txt"
done
