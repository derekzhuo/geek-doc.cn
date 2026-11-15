#!/usr/bin/env bash
# LP20: systemd 单元资源指令如何落到 cgroup v2 接口
set -u
LOGDIR="$(dirname "$0")/logs-lp20"
mkdir -p "$LOGDIR"
if [ "$(id -u)" -ne 0 ]; then echo "need root"; exit 1; fi
cd "$(dirname "$0")"

echo "==== 环境 ===="
systemd --version | head -1
stat -fc '%T' /sys/fs/cgroup
mount | grep ' /sys/fs/cgroup ' | head -1
nproc

svc=pp-lp20-test.service

wait_inactive() { # unit, max_wait_s
  local u=$1 max=$2 i=0
  while [ "$i" -lt "$max" ]; do
    local st
    st=$(systemctl show "$u" -p ActiveState --value)
    [ "$st" = "inactive" ] && return 0
    [ "$st" = "failed" ] && return 0
    sleep 1; i=$((i+1))
  done
  echo "wait_inactive: timeout after ${max}s, state=$(systemctl show "$u" -p ActiveState --value)"
}

cg_full() { printf '/sys/fs/cgroup%s' "$1"; }

dump_directives() { # cg_full_path
  local cgp=$1
  echo "---- cgroup v2 原始接口对照 ----"
  for f in memory.max memory.high memory.swap.max cpu.weight io.weight; do
    [ -e "$cgp/$f" ] && printf '%s = %s\n' "$f" "$(cat "$cgp/$f")"
  done
}

# 快速轮询：OOM 可能在 1 秒内发生，sleep 2 会错过存活期
sample_until_dead() { # cg_full_path interval max_ticks
  local cgp=$1 iv=$2 max=$3 i=0
  echo "---- 运行中轮询（每 ${iv}s，最多 ${max} 次） ----"
  while [ "$i" -lt "$max" ]; do
    if [ -d "$cgp" ]; then
      local ev
      ev=$(grep -E '^(high|max|oom |oom_kill) ' "$cgp/memory.events" 2>/dev/null | tr '\n' ';')
      echo "tick=$i state=$(systemctl show "$svc" -p ActiveState --value) $ev"
      local st
      st=$(systemctl show "$svc" -p ActiveState --value)
      [ "$st" = "inactive" ] || [ "$st" = "failed" ] && return 0
    else
      echo "tick=$i cgroup 目录已消失"
      return 0
    fi
    sleep "$iv"; i=$((i+1))
  done
}

run_case() { # name directive-args...
  local name=$1; shift
  systemctl reset-failed "$svc" 2>/dev/null
  systemctl stop "$svc" 2>/dev/null
  echo "==================== CASE $name ===================="
  # shellcheck disable=SC2086
  # 不加 --collect：失败单元需保留到终态查询，下一轮 run_case 自行 reset-failed
  # shellcheck disable=SC2086
  systemd-run --unit="$svc" "$@" stress-ng --vm 1 --vm-bytes 120M --timeout 20s 2>&1
  # 立即取一次指令落点（不等 sleep，防快死单元）
  local cg cgp i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    cg=$(systemctl show "$svc" -p ControlGroup --value)
    [ -n "$cg" ] && break
    sleep 0.2
  done
  cgp=$(cg_full "$cg")
  echo "cgroup path: $cg"
  echo "---- systemctl show 资源指令落点 ----"
  systemctl show "$svc" -p ControlGroup -p MemoryMax -p MemoryHigh -p CPUWeight -p IOWeight -p MemorySwapMax 2>&1
  [ -d "$cgp" ] && dump_directives "$cgp"
  sample_until_dead "$cgp" 0.5 50
  echo "---- 终态 ----"
  systemctl show "$svc" -p ActiveState -p SubState -p Result -p ExecMainStatus -p OOMScoreAdjust
  journalctl -u "$svc" --no-pager -n 10 | sed 's/^/journal: /'
}

# A：MemoryMax=60M 且 MemorySwapMax=0，120M 工作集无处安放 -> 真 cgroup OOM，单元失败
run_case A -p MemoryMax=60M -p MemorySwapMax=0
# B：MemoryHigh=80M 软限 + MemorySwapMax=120M -> 节流回收换出，进程存活
run_case B -p MemoryHigh=80M -p MemorySwapMax=120M

echo "---- 内核 OOM 证据（dmesg） ----"
dmesg | grep -iE 'out of memory|oom-kill|killed process' | tail -6 || echo "(dmesg 无 OOM 记录)"

# C：CPUWeight 双单元、每单元 2 个 runner 在 2 vCPU 上制造超额订阅，权重差才体现为 CPU 时间差
systemctl stop pp-w1 pp-w2 2>/dev/null; systemctl reset-failed pp-w1 pp-w2 2>/dev/null
echo "==================== CASE C CPUWeight 对照（超额订阅） ===================="
systemd-run --unit=pp-w1 -p CPUWeight=100 stress-ng --cpu 2 --timeout 14s
systemd-run --unit=pp-w2 -p CPUWeight=1000 stress-ng --cpu 2 --timeout 14s
sample_cpu() { # tag
  local tag=$1
  for u in pp-w1 pp-w2; do
    local cg cgp
    cg=$(systemctl show "$u.service" -p ControlGroup --value)
    cgp=$(cg_full "$cg")
    echo "[$tag] $u cg=$cg weight=$(cat "$cgp/cpu.weight" 2>/dev/null) state=$(systemctl show "$u.service" -p ActiveState --value)"
    grep -E 'usage_usec|nr_periods|nr_throttled' "$cgp/cpu.stat" 2>/dev/null | sed 's/^/    /'
  done
}
sleep 4;  sample_cpu t4
sleep 6;  sample_cpu t10
wait_inactive pp-w1.service 20
wait_inactive pp-w2.service 20
for u in pp-w1 pp-w2; do
  echo "$u 终态: $(systemctl show "$u.service" -p Result -p ExecMainStatus --value | tr '\n' ' ')"
done
echo "ALL DONE"
