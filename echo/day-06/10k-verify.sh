#!/bin/bash
# 10k-verify.sh — Day 6 主线实验：调高 FD 后验证 10K 连接稳定运行
#
# 动机：Day 6 README 的验证清单（10K 连接全部建立 / 5 分钟稳定 / FD≈连接数+开销 /
#       脚本可执行）目前全是"计划"，从未上机验证。本脚本用仓库真实工具逐条打勾：
#   服务端  echo-mt-server（thread-per-core + SO_REUSEPORT，Day 4 产物）:
#            ./echo-mt-server <port> <threads> et
#   客户端  echo-kp-bench（长连接压测，--mode long，MAX_CONNS=10000）:
#            ./echo-kp-bench 127.0.0.1 <port> <conns> <rounds> --mode long
# 注：Day 6 README 里的 echo-server --workers / --duration 300 是"理想接口"，
#     与实际工具不一致；本脚本按仓库实际工具实现同一条验证链。
#
# 用法:
#   bash 10k-verify.sh one <threads> <conns> <rounds>   单组合实验
#   bash 10k-verify.sh all [rounds]                     矩阵：线程 1/4 × 连接 1000/5000/10000
#   bash 10k-verify.sh leak <conns> [rounds] [wait]     泄漏检查：压测结束后 FD 回落基线？
#   bash 10k-verify.sh summary                          汇总 results/10k-SUMMARY.txt
#
# 目录约定（同 day-04/fd-scan.sh）:
#   $HOME/fd-experiment/results/    tag = 10k-t<threads>-c<conns> / leak-c<conns>
set -u
export PATH="$PATH:/usr/sbin:/sbin"
DIR="$HOME/fd-experiment"
RES="$DIR/results"
PORT=9988
CLK_TCK=$(getconf CLK_TCK 2>/dev/null || echo 100)
mkdir -p "$RES"

kill_srv() {
  pkill -9 -f echo-mt-server 2>/dev/null
  sleep 0.5
}

fd_count() { ls /proc/"$1"/fd 2>/dev/null | wc -l; }
thr_count() { ls /proc/"$1"/task 2>/dev/null | wc -l; }

# 稳健取 /proc/<pid>/stat 的 utime+stime：comm 可能含空格/括号，从含 ')' 的字段往后数
proc_jiffies() {
  awk '{ for(i=1;i<=NF;i++) if($i ~ /\)/) { print $(i+12)+$(i+13); exit } }' \
      /proc/"$1"/stat 2>/dev/null
}

# 采样：CPU%（0.5s 窗差分）+ 线程数 + FD + 端口级 ss 计数
SAMPLE_PID=""
sample_start() {  # $1=srvpid  $2=tag
  local pid="$1" tag="$2" prev_jiff="" prev_t=""
  (
    while kill -0 "$pid" 2>/dev/null; do
      local cur_jiff cur_t cpu="NA"
      cur_jiff=$(proc_jiffies "$pid")
      cur_t=$(date +%s.%N)
      if [ -n "$cur_jiff" ] && [ -n "$prev_jiff" ]; then
        cpu=$(awk -v a="$cur_jiff" -v b="$prev_jiff" -v t1="$prev_t" -v t2="$cur_t" -v ck="$CLK_TCK" \
              'BEGIN{ d=(t2-t1)*ck; if(d>0) printf "%.1f", (a-b)*100/d; else print 0 }')
      fi
      echo "$cur_t cpu=$cpu threads=$(thr_count "$pid") srvfd=$(fd_count "$pid") est=$(ss -tan state established "( sport = :$PORT )" 2>/dev/null | wc -l) tw=$(ss -tan state time-wait "( sport = :$PORT or dport = :$PORT )" 2>/dev/null | wc -l)"
      prev_jiff=$cur_jiff; prev_t=$cur_t
      sleep 0.5
    done
  ) > "$RES/cpu-$tag.log" &
  SAMPLE_PID=$!
}

run_one() {  # $1=threads $2=conns $3=rounds
  local threads=$1 conns=$2 rounds=$3
  local tag="10k-t${threads}-c${conns}"
  echo "===== [run] threads=${threads} conns=${conns} rounds=${rounds} ====="

  kill_srv
  ./echo-mt-server "$PORT" "$threads" et > "$RES/srv-$tag.log" 2>&1 &
  local srv_pid=$!

  local ok=""
  for _ in $(seq 1 100); do
    if ss -tln | grep -q ":$PORT "; then ok=1; break; fi
    sleep 0.2
  done
  if [ -z "$ok" ]; then
    echo "[srv] FAILED to listen"; tail -5 "$RES/srv-$tag.log"
    kill_srv; return 1
  fi

  # 基线 FD（listen+epoll+stdio，连接未进来之前）
  local base_fd
  base_fd=$(fd_count "$srv_pid")
  echo "[srv] pid=$srv_pid threads=$threads baseline_fd=$base_fd"

  sample_start "$srv_pid" "$tag"

  ( ulimit -n 65535; exec ./echo-kp-bench 127.0.0.1 "$PORT" "$conns" "$rounds" --mode long > "$RES/bench-$tag.txt" 2>&1 )
  local bench_rc=$?

  kill "$SAMPLE_PID" 2>/dev/null
  kill_srv

  # 解析关键指标
  local okc fail qps p50 p99 p999 max_cpu peak_fd peak_est peak_tw fd_overhead="NA"
  okc=$(grep -oP 'ok:\d+'   "$RES/bench-$tag.txt" | head -1 | sed 's/ok://')
  fail=$(grep -oP 'fail:\d+' "$RES/bench-$tag.txt" | head -1 | sed 's/fail://')
  qps=$(grep -oP 'QPS:\s+\K[0-9.]+' "$RES/bench-$tag.txt" | head -1)
  p50=$(grep -oP 'P50:\s+\K[0-9]+' "$RES/bench-$tag.txt" | head -1)
  p99=$(grep -oP 'P99:\s+\K[0-9]+' "$RES/bench-$tag.txt" | head -1)
  p999=$(grep -oP 'P999:\s+\K[0-9]+' "$RES/bench-$tag.txt" | head -1)
  max_cpu=$(awk -F'cpu=' '{v=$2; sub(/ .*/,"",v); if(v!="NA" && v!="") print v}' "$RES/cpu-$tag.log" 2>/dev/null | sort -n | tail -1)
  peak_fd=$(awk -F'srvfd=' '{print $2}' "$RES/cpu-$tag.log" | awk '{print $1}' | sort -n | tail -1)
  peak_est=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^est=/) {split($i,a,"="); print a[2]}}' "$RES/cpu-$tag.log" | sort -n | tail -1)
  peak_tw=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^tw=/) {split($i,a,"="); print a[2]}}' "$RES/cpu-$tag.log" | sort -n | tail -1)
  if [ -n "${peak_fd:-}" ] && [ -n "$base_fd" ]; then fd_overhead=$((peak_fd - conns)); fi

  echo "[res] threads=$threads conns=$conns rounds=$rounds | bench_rc=$bench_rc ok=${okc:-NA} fail=${fail:-NA} qps=${qps:-NA} | p50=${p50:-NA}us p99=${p99:-NA}us p999=${p999:-NA}us | peak srvfd=${peak_fd:-NA}(≈conns+$fd_overhead) est=${peak_est:-NA} tw=${peak_tw:-NA} cpu_max=${max_cpu:-NA}% baseline_fd=$base_fd"
  echo "[res] threads=$threads conns=$conns rounds=$rounds | bench_rc=$bench_rc ok=${okc:-NA} fail=${fail:-NA} qps=${qps:-NA} | p50=${p50:-NA}us p99=${p99:-NA}us p999=${p999:-NA}us | peak srvfd=${peak_fd:-NA}(≈conns+$fd_overhead) est=${peak_est:-NA} tw=${peak_tw:-NA} cpu_max=${max_cpu:-NA}% baseline_fd=$base_fd" >> "$RES/10k-SUMMARY.txt"
}

run_leak() {  # $1=conns $2=rounds $3=wait_after(秒)
  local conns=${1:-10000} rounds=${2:-20} wait=${3:-60}
  local tag="leak-c${conns}"
  echo "===== [leak] conns=$conns rounds=$rounds wait_after=${wait}s ====="

  kill_srv
  ./echo-mt-server "$PORT" 4 et > "$RES/srv-$tag.log" 2>&1 &
  local srv_pid=$!

  local ok=""
  for _ in $(seq 1 100); do
    if ss -tln | grep -q ":$PORT "; then ok=1; break; fi
    sleep 0.2
  done
  [ -z "$ok" ] && { echo "[srv] FAILED"; tail -5 "$RES/srv-$tag.log"; kill_srv; return 1; }

  local base_fd
  base_fd=$(fd_count "$srv_pid")
  echo "[srv] pid=$srv_pid baseline_fd=$base_fd"

  ( ulimit -n 65535; exec ./echo-kp-bench 127.0.0.1 "$PORT" "$conns" "$rounds" --mode long > "$RES/bench-$tag.txt" 2>&1 )
  echo "[bench] done rc=$?，开始 ${wait}s 回落观测…"

  # 压测结束后持续采样：FD 应回落基线，est→0，TW 衰减
  local t
  for t in $(seq 1 "$wait"); do
    echo "$(date +%s.%N) srvfd=$(fd_count "$srv_pid") est=$(ss -tan state established "( sport = :$PORT )" 2>/dev/null | wc -l) tw=$(ss -tan state time-wait "( sport = :$PORT or dport = :$PORT )" 2>/dev/null | wc -l)"
    sleep 1
  done > "$RES/sample-$tag.log"

  local final_fd tw_end leak_verdict
  final_fd=$(fd_count "$srv_pid")
  # 回落观测期结束时的 TIME_WAIT 数（观察 TW 衰减）
  tw_end=$(tail -1 "$RES/sample-$tag.log" | grep -oP 'tw=\d+' | cut -d= -f2)
  if ! kill -0 "$srv_pid" 2>/dev/null; then
    leak_verdict="SRV-DEAD（进程退出，需查 $RES/srv-$tag.log）"
  elif [ "$final_fd" -gt $((base_fd + 5)) ]; then
    leak_verdict="LEAK! final_fd($final_fd) > baseline($base_fd)+5"
  else
    leak_verdict="OK 无泄漏，FD 回落基线($base_fd)"
  fi
  echo "[res] conns=$conns baseline_fd=$base_fd final_fd=$final_fd tw_after_${wait}s=${tw_end:-NA} verdict=$leak_verdict"
  echo "[res] conns=$conns baseline_fd=$base_fd final_fd=$final_fd tw_after_${wait}s=${tw_end:-NA} verdict=$leak_verdict" >> "$RES/10k-SUMMARY.txt"
  kill_srv
}

run_all() {  # $1=rounds
  local rounds=${1:-20}
  echo "=== 10K 验证矩阵 (rounds=$rounds) ===" | tee "$RES/10k-SUMMARY.txt"
  for threads in 1 4; do
    for conns in 1000 5000 10000; do
      run_one "$threads" "$conns" "$rounds"
    done
  done
  echo "=== 完成，见 $RES/10k-SUMMARY.txt ==="
}

show_summary() {
  echo "==== 10k-SUMMARY.txt ===="
  cat "$RES/10k-SUMMARY.txt" 2>/dev/null || echo "(无 10k-SUMMARY.txt，先运行 bash 10k-verify.sh all)"
}

case "${1:-}" in
  one)     run_one "${2:?threads}" "${3:?conns}" "${4:?rounds}" ;;
  all)     run_all "${2:-20}" ;;
  leak)    run_leak "${2:-10000}" "${3:-20}" "${4:-60}" ;;
  summary) show_summary ;;
  *)       sed -n '1,42p' "$0" | grep -E '^# ' | sed 's/^# //' ;;
esac
