#!/bin/bash
# PPS 采集 + 短连接雪崩验证
# 在 A 上执行：服务端 8 线程，B 端压测 15 秒，同时 A 端抓 sar -n DEV 与 TIME_WAIT
# 用法: bash pps_test.sh <long|short> <conns> <tag>
MODE=${1:-long}
CONNS=${2:-1000}
TAG=${3:-t1}
DIR=/root/echo-day04
RES=$DIR/results_split_v2
PORT=9988

pkill -9 -x echo-mt-server 2>/dev/null; sleep 1
(cd $DIR && nohup ./echo-mt-server $PORT 8 lt > /tmp/srv.log 2>&1 &)
sleep 2

echo "== [$TAG] 压测开始: mode=$MODE conns=$CONNS 15s =="
# A 端后台采集网络 PPS 与 TIME_WAIT
(sar -n DEV 1 15 > $RES/pps-$TAG.txt 2>&1 &)
(for i in $(seq 1 15); do echo "$(date +%s) tw=$(ss -s | grep -o 'timewait [0-9]*' | awk '{print $2}') syn=$(ss -s | grep -o 'SYN [0-9]*' | awk '{print $2}')"; sleep 1; done > $RES/tw-$TAG.txt 2>&1 &)

# B 端压测
if [ "$MODE" = long ]; then R=3000; else R=1200; fi
ssh -o BatchMode=yes root@10.206.0.2 "cd $DIR && ulimit -n 65535 && ./echo-kp-bench 10.206.0.10 $PORT $CONNS $R --mode $MODE > $RES/ppsbench-$TAG.txt"

echo "== [$TAG] 完成 =="
echo "--- bench 摘要 ---"
grep -E "^ QPS|^  P50|^  P99" $RES/ppsbench-$TAG.txt
echo "--- PPS 摘要（rxpck/s）---"
grep -E "eth0" $RES/pps-$TAG.txt | awk '{print $3, $5}' | tail -16
echo "--- TIME_WAIT 采样（首/尾）---"
head -2 $RES/tw-$TAG.txt
tail -2 $RES/tw-$TAG.txt
