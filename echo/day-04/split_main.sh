#!/bin/bash
# 拆机实验总控（host1=服务端 32核，host2=客户端 8核，内网通信 10.206.0.0/20）
# 用法: bash split_main.sh <phase>    phase: 51|52|53|54|all
#   51 线程数扩展  52 LT vs ET  53 连接数扫描  54 CPU 利用率
SRV=10.206.0.11
CLI=10.206.0.15
PW=Hoi720081005
PORT=9988
DIR=/root/echo-day04
RES=$DIR/results_split
mkdir -p $RES

ssh_cmd() { sshpass -p "$PW" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$CLI" "cd $DIR && ulimit -n 65535 && $1"; }

start_server() {  # $1=threads $2=lt|et
  pkill -9 -x echo-mt-server 2>/dev/null; sleep 1
  (cd $DIR && nohup ./echo-mt-server $PORT $1 $2 > /tmp/srv.log 2>&1 &)
  sleep 2
  local cnt=$(ss -tln | grep -c ":$PORT")
  echo "[srv] threads=$1 mode=$2 listen=$cnt"
}

bench() {  # $1=conns $2=rounds $3=mode $4=outfile
  ssh_cmd "./echo-kp-bench $SRV $PORT $1 $2 --mode $3 > $RES/$4"
}

phase51() {  # 线程数扩展: LT 长连接 1000 连接 × 1000 轮, 每档 3 轮
  for n in 1 2 4 8 16 32; do
    start_server $n lt
    for i in 1 2 3; do
      bench 1000 1000 long "51-t$n-r$i.txt"
    done
    echo "[51] done t$n"
  done
}

phase52() {  # LT vs ET: 8 线程 × {lt,et} × {long,short} × {100,1000}
  for m in lt et; do
    start_server 8 $m
    for mode in long short; do
      if [ "$mode" = long ]; then r=3000; else r=1200; fi
      for c in 100 1000; do
        for i in 1 2 3; do
          bench $c $r $mode "52-$m-c$c-$mode-r$i.txt"
        done
      done
    done
    echo "[52] done $m"
  done
}

phase53() {  # 连接数扫描: 8 线程 LT × {short,long} × 100..5000, 每配置 2 轮
  start_server 8 lt
  for c in 100 500 1000 2000 5000; do
    for mode in short long; do
      if [ "$mode" = long ]; then r=2000; else r=800; fi
      for i in 1 2; do
        bench $c $r $mode "53-scan-c$c-$mode-r$i.txt"
      done
    done
    echo "[53] done c$c"
  done
}

phase54() {  # CPU 利用率: 1/4/8/16 线程, 压测 ~15s 同时 pidstat(host1)+mpstat(host2)
  for n in 1 4 8 16; do
    start_server $n lt
    local srvpid=$(pgrep -x echo-mt-server | head -1)
    ssh_cmd "(mpstat -P ALL 1 15 > $RES/mp-t$n.txt 2>&1 &) ; ./echo-kp-bench $SRV $PORT 1000 10000 --mode long > $RES/54-bench-t$n.txt" &
    pidstat -p "$srvpid" 1 15 > $RES/cpu-t$n.txt 2>&1
    wait
    echo "[54] done t$n"
  done
}

case "${1:-all}" in
  51) phase51;;
  52) phase52;;
  53) phase53;;
  54) phase54;;
  all) phase51; phase52; phase53; phase54;;
esac
echo "ALL DONE"
