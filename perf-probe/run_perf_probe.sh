#!/usr/bin/env bash
# run_perf_probe.sh —— 一键编译并运行「动态探针插桩」对比实验
#
# 本脚本覆盖三大类、共 5 个对照实验（见 README §3 / §7）：
#   A. perf probe (uprobe) 动态插桩：入口 / 入口+返回 双探针
#   B. USDT 静态预埋：perf probe --add 'usdt_demo:work_enter'
#   C. ftrace function tracer：作为「不抓参数、仅计数」的对照
#   D. 性能基线：bench 模式量化插桩固有开销
#
# 用法：
#   bash run_perf_probe.sh             # 跑全部（Linux）
#   bash run_perf_probe.sh uprobe      # 仅 uprobe 动态插桩
#   bash run_perf_probe.sh usdt        # 仅 USDT 静态点
#   bash run_perf_probe.sh ftrace      # 仅 ftrace 对照
#   bash run_perf_probe.sh bench       # 仅性能基线
#   bash run_perf_probe.sh --list      # 只列出步骤
#
# 平台：编译跨平台；运行时依赖 Linux + perf + uprobe/ftrace。
#       部分命令需 root（uprobe_events / ftrace），建议 sudo 运行。
#
set -u

D="$(cd "$(dirname "$0")" && pwd)"
LOG="$D/experiments-perf-probe-$(date +%Y%m%d-%H%M%S).log"
MODE="${1:-all}"
DO_LIST=0
[ "$MODE" = "--list" ] && DO_LIST=1

BIN="perf_probe_demo"
USDT_BIN="usdt_demo"

IS_LINUX=0
[ "$(uname -s)" = "Linux" ] && IS_LINUX=1

: > "$LOG"

step() {
  echo
  echo "############################################################"
  echo "# $1"
  echo "############################################################"
  echo "$1" >> "$LOG"
}
run() {
  echo "\$ $*"
  echo "\$ $*" >> "$LOG"
  { "$@" ; } 2>&1 | tee -a "$LOG"
  echo "" >> "$LOG"
}
skip() {
  echo "  [跳过] $1"
  echo "[跳过] $1" >> "$LOG"
}

if [ "$DO_LIST" -eq 1 ]; then
  echo "  模式 all/uprobe/usdt/ftrace/bench"
  echo "  [步骤] make（编译 perf_probe_demo + usdt_demo[Linux]）"
  echo "  [A uprobe]  perf probe -x ./$BIN --add 'do_work n=%di'"
  echo "  [A uprobe]  perf probe -x ./$BIN --add 'do_work%return'"
  echo "  [A uprobe]  perf stat 验证命中 + perf record + perf script 对账"
  echo "  [B usdt]    readelf -n ./$USDT_BIN | grep stapsdt"
  echo "  [B usdt]    perf probe -x ./$USDT_BIN --add 'usdt_demo:work_enter'"
  echo "  [B usdt]    perf stat 验证命中"
  echo "  [C ftrace]  echo 1 > set_ftrace_filter; echo function > current_tracer"
  echo "  [C ftrace]  cat trace | grep work"
  echo "  [D bench]   ./$BIN bench 5"
  echo "  [清理]      perf probe --del '*'; ftrace reset"
  exit 0
fi

# ───────── 1. 编译 ─────────
step "编译（make）"
( cd "$D" && make clean && make )
if [ ! -x "$D/$BIN" ]; then echo "编译失败"; exit 1; fi

if [ "$IS_LINUX" -ne 1 ]; then
  skip "perf probe / ftrace 需要 Linux（当前非 Linux）。仅演示 bench 本地可跑："
  ( cd "$D" && ./$BIN bench 3 )
  exit 0
fi

# ───────── A. uprobe 动态插桩 ─────────
if [ "$MODE" = "all" ] || [ "$MODE" = "uprobe" ]; then
  step "A. uprobe 动态插桩：入口 + 返回双探针"
  ( cd "$D" && sudo perf probe --del '*' 2>&1 ) | tee -a "$LOG"
  ( cd "$D" && sudo perf probe -x ./$BIN --add 'do_work n=%di' ) 2>&1 | tee -a "$LOG"
  ( cd "$D" && sudo perf probe -x ./$BIN --add 'do_work%return' ) 2>&1 | tee -a "$LOG"
  ( cd "$D" && sudo perf probe -l ) 2>&1 | tee -a "$LOG"
  echo "  内核 uprobe_events:" | tee -a "$LOG"
  ( cd "$D" && sudo cat /sys/kernel/debug/tracing/uprobe_events 2>&1 ) | tee -a "$LOG"

  ENTRY="probe_perf_probe_demo:do_work"
  RET="probe_perf_probe_demo:do_work__return"
  step "A. perf stat 三方对账（程序自统计 vs 入口 vs 返回）"
  ( cd "$D" && sudo perf stat -e "$ENTRY" -e "$RET" -- ./$BIN 5 2>&1 ) | tee -a "$LOG"
  step "A. perf record + perf script（导出逐次调用）"
  ( cd "$D" && sudo perf record -e "$ENTRY" -e "$RET" -o perf.data -- ./$BIN 30 2>&1 ) | tee -a "$LOG"
  ( cd "$D" && sudo perf script -i perf.data 2>&1 | head -20 ) | tee -a "$LOG"
  ( cd "$D" && sudo perf probe --del '*' ) 2>&1 | tee -a "$LOG"
fi

# ───────── B. USDT 静态预埋 ─────────
if [ "$MODE" = "all" ] || [ "$MODE" = "usdt" ]; then
  step "B. USDT 静态预埋点"
  if [ ! -x "$D/$USDT_BIN" ]; then
    echo "  usdt_demo 未编译（仅 Linux），尝试构建..." | tee -a "$LOG"
    ( cd "$D" && make usdt ) | tee -a "$LOG"
  fi
  if [ ! -x "$D/$USDT_BIN" ]; then
    skip "usdt_demo 构建失败（缺 <sys/sdt.h>？），跳过 USDT 实验"
  else
    ( cd "$D" && readelf -n ./$USDT_BIN 2>/dev/null | grep -A4 stapsdt ) | tee -a "$LOG"
    ( cd "$D" && sudo perf probe --del '*' 2>&1 ) | tee -a "$LOG"
    ( cd "$D" && sudo perf probe -x ./$USDT_BIN --add 'usdt_demo:work_enter' ) 2>&1 | tee -a "$LOG"
    ( cd "$D" && sudo perf probe -l ) 2>&1 | tee -a "$LOG"
    step "B. perf stat 验证 USDT 命中"
    ( cd "$D" && sudo perf stat -e probe_usdt_demo:work_enter -- ./$USDT_BIN 5 2>&1 ) | tee -a "$LOG"
    ( cd "$D" && sudo perf probe --del '*' ) 2>&1 | tee -a "$LOG"
  fi
fi

# ───────── C. ftrace function tracer 对照 ─────────
if [ "$MODE" = "all" ] || [ "$MODE" = "ftrace" ]; then
  step "C. ftrace function tracer（仅计数/调用栈，不抓参数）"
  T="/sys/kernel/debug/tracing"
  sudo sh -c "echo > $T/set_ftrace_filter" 2>/dev/null
  sudo sh -c "echo 'do_work' > $T/set_ftrace_filter" 2>/dev/null
  sudo sh -c "echo function > $T/current_tracer" 2>/dev/null
  ( cd "$D" && ./$BIN 5 >/dev/null 2>&1 )
  echo "  ftrace trace 中 do_work 命中（节选）:" | tee -a "$LOG"
  sudo grep -c "do_work" "$T/trace" 2>/dev/null | tee -a "$LOG"
  sudo sh -c "echo nop > $T/current_tracer" 2>/dev/null
  sudo sh -c "echo > $T/set_ftrace_filter" 2>/dev/null
fi

# ───────── D. 性能基线 ─────────
if [ "$MODE" = "all" ] || [ "$MODE" = "bench" ]; then
  step "D. 性能基线（量化插桩固有开销）"
  ( cd "$D" && ./$BIN bench 5 ) | tee -a "$LOG"
fi

echo
echo "============================================================"
echo " 实验完成。日志: $LOG"
echo "============================================================"
