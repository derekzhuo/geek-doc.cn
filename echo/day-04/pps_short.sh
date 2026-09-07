#!/bin/bash
# 短连接雪崩验证 + PPS 采集（抓 SYN-recv 与 time-wait 真实计数）
MODE=${1:-short}
CONNS=${2:-1000}
TAG=${3:-short-c1000}
DIR=/root/echo-day04
RES=$DIR/results_split_v2
PORT=9988

pkill -9 -x echo-mt-server 2>/dev/null; sleep 1
(cd $DIR && nohup ./echo-mt-server $PORT 8 lt > /tmp/srv.log 2>&1 &)
sleep 2

echo "== [$TAG] 压测开始: mode=$MODE conns=$CONNS 15s =="
(sar -n DEV 1 16 > $RES/pps-$TAG.txt 2>&1 &)
(for i in $(seq 1 16); do
  tw=$(ss -tan state time-wait | wc -l)
  syn=$(ss -tan state syn-recv | wc -l)
  est=$(ss -tan state established | wc -l)
  echo "$i tw=$tw syn=$syn est=$est"
  sleep 1
done > $RES/tw-$TAG.txt 2>&1 &)

R=1200
ssh -o BatchMode=yes root@10.206.0.2 "cd $DIR && ulimit -n 65535 && ./echo-kp-bench 10.206.0.10 $PORT $CONNS $R --mode short > $RES/ppsbench-$TAG.txt"

echo "== [$TAG] 完成 =="
