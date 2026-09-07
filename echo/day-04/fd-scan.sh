#!/bin/bash
# fd-scan.sh — FD/ulimit 回归实验（Day 4 前置实验，阶段 2 前传）
#
# 动机：Day 4 拆机实验从第一天就预置 ulimit -n 65535，"FD 撞墙"从未被实测。
#       本实验把 Day 3 那堵"看不见的墙"显式化：默认 1024 下服务端能扛多少连接？
#       撞墙现象是什么？调高 ulimit 后墙从"FD"转移到"单线程 epoll"的拐点在哪？
#
# 设计原则：与 Day 3 同一把尺子 —— echo-epoll-lt-server（单线程 LT）+ echo-kp-bench 长连接，
#           连接数档位 100/500/1000/2000/5000 完全复用，仅多一列"ulimit 变量"。
#
# 用法:
#   bash fd-scan.sh one <srv_ul> <conns> <rounds> <cli_ul>   单组合实验
#   bash fd-scan.sh all [rounds]                            全矩阵（默认 rounds=50）
#   bash fd-scan.sh summary                                 汇总 results/ 为对照表
#
# 目录约定:
#   $HOME/fd-experiment/           程序与结果根目录
#   $HOME/fd-experiment/results/   bench/sample/srv 日志
# 命名:  bench-s<srv_ul>-c<conns>-cli<cli_ul>.txt 等
#
# 关键实现点:
#   - ulimit 必须在启动进程的同一 subshell 内设置（ulimit 仅对当前 shell 生效）
#   - exec 保证 subshell PID 即服务端 PID，供 /proc/<pid>/fd 采样
#   - 客户端/服务端 ulimit 分开控制，才能回答"撞墙时是谁的 FD 不够"

set -u
# CentOS 下 ss/netstat 位于 /usr/sbin，普通用户 PATH 常不含，显式补上
export PATH="$PATH:/usr/sbin:/sbin"
DIR="$HOME/fd-experiment"
RES="$DIR/results"
PORT=9988
mkdir -p "$RES"

kill_srv() {
  pkill -9 -f echo-epoll-lt-server 2>/dev/null
  sleep 0.5
}

fd_count() { ls /proc/"$1"/fd 2>/dev/null | wc -l; }

# 后台采样：服务端 fd + ss 各状态计数，每 0.2s 一行
SAMPLE_PID=""
sample_start() {  # $1=srvpid  $2=tag
  local tag="$2"
  (
    while kill -0 "$1" 2>/dev/null; do
      echo "$(date +%s.%N) srvfd=$(fd_count "$1") est=$(ss -tan state established 2>/dev/null | wc -l) syn=$(ss -tan state syn-recv 2>/dev/null | wc -l) tw=$(ss -tan state time-wait 2>/dev/null | wc -l)"
      sleep 0.2
    done
  ) > "$RES/sample-$2.log" &
  SAMPLE_PID=$!
}

run_one() {  # $1=srv_ul  $2=conns  $3=rounds  $4=cli_ul
  local srv_ul=$1 conns=$2 rounds=$3 cli_ul=$4
  local tag="s${srv_ul}-c${conns}-cli${cli_ul}"
  echo "===== [run] srv_ul=${srv_ul} conns=${conns} rounds=${rounds} cli_ul=${cli_ul} ====="

  kill_srv

  # 1. 启动服务端（受限 ulimit，exec 保持 PID）
  ( ulimit -n "$srv_ul"; exec ./echo-epoll-lt-server > "$RES/srv-$tag.log" 2>&1 ) &
  local srv_pid=$!
  echo "[srv] pid=$srv_pid ulimit=$srv_ul"

  # 2. 等待监听就绪
  local ok=""
  for _ in $(seq 1 50); do
    if ss -tln | grep -q ":$PORT "; then ok=1; break; fi
    sleep 0.2
  done
  if [ -z "$ok" ]; then
    echo "[srv] FAILED to listen (port busy or EMFILE at bind?)"; tail -3 "$RES/srv-$tag.log"
    kill_srv; return 1
  fi

  # 3. 启动采样
  sample_start "$srv_pid" "$tag"

  # 4. 客户端压测（受限 ulimit）——长连接模式，与 Day 3 对齐
  ( ulimit -n "$cli_ul"; exec ./echo-kp-bench 127.0.0.1 "$PORT" "$conns" "$rounds" --mode long > "$RES/bench-$tag.txt" 2>&1 )
  local bench_rc=$?

  # 5. 收尾
  kill "$SAMPLE_PID" 2>/dev/null
  kill_srv

  # 6. 解析关键指标
  local fail qps srv_emfile srv_ok peak_est peak_syn peak_tw peak_fd
  fail=$(grep -oP 'ok:\d+ fail:\d+' "$RES/bench-$tag.txt" | grep -oP '\d+ fail:\d+' | grep -oP 'fail:\d+' | sed 's/fail://' | head -1)
  qps=$(grep -oP 'QPS:\s+\K[0-9.]+' "$RES/bench-$tag.txt" | head -1)
  srv_emfile=$(grep -c 'Too many open files' "$RES/srv-$tag.log")
  srv_ok=$(grep -c 'new connection' "$RES/srv-$tag.log")
  peak_fd=$(awk -F'srvfd=' '{print $2}' "$RES/sample-$tag.log" | awk '{print $1}' | sort -n | tail -1)
  peak_est=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^est=/) {split($i,a,"="); print a[2]}}' "$RES/sample-$tag.log" | sort -n | tail -1)
  peak_syn=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^syn=/) {split($i,a,"="); print a[2]}}' "$RES/sample-$tag.log" | sort -n | tail -1)
  peak_tw=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^tw=/) {split($i,a,"="); print a[2]}}' "$RES/sample-$tag.log" | sort -n | tail -1)

  echo "[res] conns=$conns srv_ul=$srv_ul cli_ul=$cli_ul | bench_rc=$bench_rc fail=${fail:-NA} qps=${qps:-NA} | srv_ok=$srv_ok srv_emfile=$srv_emfile | peak srvfd=${peak_fd:-NA} est=${peak_est:-NA} syn=${peak_syn:-NA} tw=${peak_tw:-NA}"
  echo "[res] conns=$conns srv_ul=$srv_ul cli_ul=$cli_ul | bench_rc=$bench_rc fail=${fail:-NA} qps=${qps:-NA} | srv_ok=$srv_ok srv_emfile=$srv_emfile | peak srvfd=${peak_fd:-NA} est=${peak_est:-NA} syn=${peak_syn:-NA} tw=${peak_tw:-NA}" >> "$RES/SUMMARY.txt"
}

run_all() {  # $1=rounds
  local rounds=${1:-50}
  local cli_ul
  echo "=== FD 回归实验全矩阵 (rounds=$rounds) ===" | tee "$RES/SUMMARY.txt"

  # ── 主矩阵：客户端放行 65535，隔离服务端 FD 墙 ──
  echo "── 主矩阵：客户端 ulimit=65535（放行），变化服务端 ulimit ──"
  for srv_ul in 1024 8192 65535; do
    for conns in 100 500 1000 2000 5000; do
      run_one "$srv_ul" "$conns" "$rounds" 65535
    done
  done

  # ── 对照矩阵：客户端同限，回答"撞墙时是谁的 FD 不够" ──
  echo "── 对照矩阵：客户端同限（srv==cli）──"
  for srv_ul in 1024 8192; do
    for conns in 2000 5000; do
      run_one "$srv_ul" "$conns" "$rounds" "$srv_ul"
    done
  done

  echo "=== 完成，见 $RES/SUMMARY.txt ==="
}

show_summary() {
  echo "==== SUMMARY.txt ===="
  cat "$RES/SUMMARY.txt" 2>/dev/null || echo "(无 SUMMARY.txt，先运行 bash fd-scan.sh all)"
}

case "${1:-}" in
  one)     run_one "${2:?srv_ul}" "${3:?conns}" "${4:?rounds}" "${5:?cli_ul}" ;;
  all)     run_all "${2:-50}" ;;
  summary) show_summary ;;
  *)       sed -n '1,40p' "$0" | grep -E '^# ' | sed 's/^# //' ;;
esac
