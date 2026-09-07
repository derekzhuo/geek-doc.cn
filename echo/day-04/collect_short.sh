#!/bin/bash
# 汇总短连接雪崩场景全部数据（A端 pps/tw + B端 bench）
echo "===== B端 bench: ppsbench-short-c1000 ====="
ssh -o BatchMode=yes root@10.206.0.2 "grep -E '^ QPS|^  P50|^  P99|^  P999|success' /root/echo-day04/results_split_v2/ppsbench-short-c1000.txt"
echo ""
echo "===== A端 PPS: pps-short-c1000 (rxpck/s) ====="
awk '/eth0/{print $3, $5}' /root/echo-day04/results_split_v2/pps-short-c1000.txt
echo ""
echo "===== A端 TIME_WAIT/SYN/EST: tw-short-c1000 ====="
cat /root/echo-day04/results_split_v2/tw-short-c1000.txt
