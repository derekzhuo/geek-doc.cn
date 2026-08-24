#!/bin/bash
# exp-sustained-spin.sh — Day 5 补充实验：连接数 ≫ FD 上限时的"持续空转"
#
# 动机：
#   Day 5 E3 只测了 500 连接 / 128 FD（≈4x 比例），EMFILE 忙循环只是"一次性脉冲"：
#   CPU 峰值 ~23% 一闪而过——因为连接量小，忙循环很快被"连接建完、accept 队列见底"
#   自然解除。生产故障的形态却是**持续**空转：只要 accept 队列一直有人排队，
#   EMFILE→perror→break→epoll_wait 立即返回→accept 的循环就不会停。本实验把
#   "连接数/FD 上限"比例拉到 16x / 40x / 78x，回答：
#     Q1 忙循环从"脉冲"变"持续"的比例阈值在哪？
#     Q2 持续空转时，已建立连接的真实吞吐/延迟受损多少？
#     Q3 排队中的连接最终能全部建上，还是被 EMFILE 永久拒掉？
#
# 工具（与 Day 4/5 同一把尺子）:
#   $HOME/fd-experiment/echo-epoll-lt-server   LT 服务端，EMFILE 时 perror 一次后 break，不主动退避
#   $HOME/fd-experiment/echo-kp-bench          长连接压测 --mode long（MAX_CONNS=10000）
#
# 用法:
#   bash exp-sustained-spin.sh one <srv_ul> <conns> <rounds>   单组合实验
#   bash exp-sustained-spin.sh all [rounds]                    全矩阵（默认 rounds=20）
#   bash exp-sustained-spin.sh summary                         汇总 results/ 为对照表
#
# 目录约定（同 day-04/fd-scan.sh）:
#   $HOME/fd-experiment/results/    tag = spin-s<srv_ul>-c<conns>

set -u
export PATH="$PATH:/usr/sbin:/sbin"
DIR="$HOME/fd-experiment"
RES="$DIR/results"
PORT=9988
CLK_TCK=$(getconf CLK_TCK 2>/dev/null || echo 100)
mkdir -p "$RES"

kill_srv() {
  pkill -9 -f echo-epoll-lt-server 2>/dev/null
  sleep 0.5
}

# SIGTERM 打到子 shell 组的系统提示（Terminated/Killed）属正常，静默处理
export PS4=''


fd_count() { ls /proc/"$1"/fd 2>/dev/null | wc -l; }

# 稳健取 /proc/<pid>/stat 的 utime+stime：comm 可能含空格/括号，从含 ')' 的字段往后数
proc_jiffies() {
  awk '{ for(i=1;i<=NF;i++) if($i ~ /\)/) { print $(i+12)+$(i+13); exit } }' \
      /proc/"$1"/stat 2>/dev/null
}

# 双线采样：FD/ss/CPU%（0.5s 窗，CPU% 用真实耗时差分，任何采样间隔都正确）
SAMPLE_PID=""
sample_start() {  # $1=srvpid  $2=tag
  local pid="$1" tag="$2" prev_jiff="" prev_t=""
  (
    while kill -0 "$pid" 2>/dev/null; do
      local cur_jiff cur_t cpu="NA" line
      cur_jiff=$(proc_jiffies "$pid")
      cur_t=$(date +%s.%N)
      if [ -n "$cur_jiff" ] && [ -n "$prev_jiff" ]; then
        cpu=$(awk -v a="$cur_jiff" -v b="$prev_jiff" -v t1="$prev_t" -v t2="$cur_t" -v ck="$CLK_TCK" \
              'BEGIN{ d=(t2-t1)*ck; if(d>0) printf "%.1f", (a-b)*100/d; else print 0 }')
      fi
      echo "$cur_t cpu=$cpu srvfd=$(fd_count "$pid") est=$(ss -tan state established 2>/dev/null | wc -l) syn=$(ss -tan state syn-recv 2>/dev/null | wc -l) tw=$(ss -tan state time-wait 2>/dev/null | wc -l)"
      prev_jiff=$cur_jiff; prev_t=$cur_t
      sleep 0.5
    done
  ) > "$RES/cpu-$tag.log" &
  SAMPLE_PID=$!
}

run_one() {  # $1=srv_ul  $2=conns  $3=rounds  $4=mode(long|short)
  local srv_ul=$1 conns=$2 rounds=$3 mode=${4:-long}
  local tag="spin-s${srv_ul}-c${conns}-m${mode}" ratio=$((conns / srv_ul))
  echo "===== [run] srv_ul=${srv_ul} conns=${conns} rounds=${rounds} mode=${mode} (ratio≈${ratio}x) ====="

  kill_srv

  # 服务端受限 ulimit 启动（exec 保持 PID，供 /proc 采样）
  ( ulimit -n "$srv_ul"; exec ./echo-epoll-lt-server > "$RES/srv-$tag.log" 2>&1 ) &
  local srv_pid=$!
  echo "[srv] pid=$srv_pid ulimit=$srv_ul"

  local ok=""
  for _ in $(seq 1 50); do
    if ss -tln | grep -q ":$PORT "; then ok=1; break; fi
    sleep 0.2
  done
  if [ -z "$ok" ]; then
    echo "[srv] FAILED to listen"; tail -3 "$RES/srv-$tag.log"
    kill_srv; return 1
  fi

  sample_start "$srv_pid" "$tag"

  # 客户端放行（65535），隔离"服务端 FD 墙"这一变量；mode=short 时 client 持续建连，
  # accept 队列始终有货，EMFILE 忙循环不会因"连接建完"自然解除 → 复现持续空转
  ( ulimit -n 65535; exec ./echo-kp-bench 127.0.0.1 "$PORT" "$conns" "$rounds" --mode "$mode" > "$RES/bench-$tag.txt" 2>&1 )
  local bench_rc=$?

  { kill "$SAMPLE_PID" 2>/dev/null; } 2>/dev/null
  kill_srv 2>/dev/null

  # 解析关键指标
  local fail qps max_cpu avg_cpu srv_emfile srv_ok peak_fd peak_est peak_syn peak_tw
  fail=$(grep -oP 'fail:\d+' "$RES/bench-$tag.txt" | head -1 | sed 's/fail://')
  qps=$(grep -oP 'QPS:\s+\K[0-9.]+' "$RES/bench-$tag.txt" | head -1)
  srv_emfile=$(grep -c 'Too many open files' "$RES/srv-$tag.log")
  srv_ok=$(grep -c 'new connection' "$RES/srv-$tag.log")
  max_cpu=$(awk -F'cpu=' '{v=$2; sub(/ .*/,"",v); if(v!="NA" && v!="") print v}' "$RES/cpu-$tag.log" 2>/dev/null | sort -n | tail -1)
  avg_cpu=$(awk -F'cpu=' '{v=$2; sub(/ .*/,"",v); if(v!="NA" && v!="") {s+=v; n++}} END{if(n) printf "%.1f", s/n; else print "NA"}' "$RES/cpu-$tag.log")
  peak_fd=$(awk -F'srvfd=' '{print $2}' "$RES/cpu-$tag.log" | awk '{print $1}' | sort -n | tail -1)
  peak_est=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^est=/) {split($i,a,"="); print a[2]}}' "$RES/cpu-$tag.log" | sort -n | tail -1)
  peak_syn=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^syn=/) {split($i,a,"="); print a[2]}}' "$RES/cpu-$tag.log" | sort -n | tail -1)
  peak_tw=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^tw=/) {split($i,a,"="); print a[2]}}' "$RES/cpu-$tag.log" | sort -n | tail -1)

  echo "[res] srv_ul=$srv_ul conns=$conns ratio≈${ratio}x rounds=$rounds mode=$mode | bench_rc=$bench_rc fail=${fail:-NA} qps=${qps:-NA} | srv_ok=${srv_ok:-NA} srv_emfile=$srv_emfile | cpu max=${max_cpu:-NA} avg=${avg_cpu:-NA}% | peak srvfd=${peak_fd:-NA} est=${peak_est:-NA} syn=${peak_syn:-NA} tw=${peak_tw:-NA}"
  echo "[res] srv_ul=$srv_ul conns=$conns ratio≈${ratio}x rounds=$rounds mode=$mode | bench_rc=$bench_rc fail=${fail:-NA} qps=${qps:-NA} | srv_ok=${srv_ok:-NA} srv_emfile=$srv_emfile | cpu max=${max_cpu:-NA} avg=${avg_cpu:-NA}% | peak srvfd=${peak_fd:-NA} est=${peak_est:-NA} syn=${peak_syn:-NA} tw=${peak_tw:-NA}" >> "$RES/SUMMARY.txt"
}

run_all() {  # $1=mode  $2=rounds
  local mode=${1:-long} rounds=${2:-20}
  echo "=== 持续空转矩阵 (srv_ul=128, mode=$mode, rounds=$rounds) ===" | tee "$RES/SUMMARY.txt"
  for conns in 500 2000 5000 10000; do
    run_one 128 "$conns" "$rounds" "$mode"
  done
  echo "=== 完成，见 $RES/SUMMARY.txt ==="
}

show_summary() {
  echo "==== SUMMARY.txt ===="
  cat "$RES/SUMMARY.txt" 2>/dev/null || echo "(无 SUMMARY.txt，先运行 bash exp-sustained-spin.sh all)"
}

case "${1:-}" in
  one)     run_one "${2:?srv_ul}" "${3:?conns}" "${4:?rounds}" "${5:-long}" ;;
  all)     run_all "${2:-long}" "${3:-20}" ;;
  summary) show_summary ;;
  *)       sed -n '1,44p' "$0" | grep -E '^# ' | sed 's/^# //' ;;
esac
