#!/usr/bin/env bash
# run_false_sharing.sh —— 一键编译并运行 false-sharing 伪共享实验
#
# 功能：
#   1. 编译本目录的 false_sharing
#   2. 跑 threads = 1/2/4/8 的多线程自增对比（shared vs padded）
#   3. （可选，需 root）跑 perf c2c 看 HITM%（伪共享证据）
#   4. 全部输出同时打印屏幕并写入 experiments-false-sharing-<时间戳>.log
#
# 用法：
#   bash run_false_sharing.sh              # 只编译 + 普通运行（无需 root）
#   sudo bash run_false_sharing.sh --perf  # 额外跑 perf c2c（需 root）
#   bash run_false_sharing.sh --list       # 只列出将执行的步骤，不实际跑
#
# 平台：编译跨平台（Linux/macOS）；运行时依赖 Linux 的 /proc。
#       macOS 下可编译，但跑会提示需在 Linux 上运行。
#
set -u

D="$(cd "$(dirname "$0")" && pwd)"
LOG="$D/experiments-false-sharing-$(date +%Y%m%d-%H%M%S).log"
DO_PERF=0
DO_LIST=0

for a in "$@"; do
  case "$a" in
    --perf) DO_PERF=1 ;;
    --list) DO_LIST=1 ;;
    *) echo "未知参数: $a"; exit 1 ;;
  esac
done

: > "$LOG"

# 是否 Linux（/proc 依赖）
IS_LINUX=0
if [ "$(uname -s)" = "Linux" ]; then IS_LINUX=1; fi

# 是否 root（perf 采集通常需要）
IS_ROOT=0
if [ "$(id -u)" -eq 0 ]; then IS_ROOT=1; fi

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
  # 命令输出同时到屏幕和日志；失败不中断脚本
  { "$@" ; } 2>&1 | tee -a "$LOG"
  echo "" >> "$LOG"
}
skip() {
  echo "  [跳过] $1"
  echo "[跳过] $1" >> "$LOG"
}

list_only=0
[ "$DO_LIST" -eq 1 ] && list_only=1

run_demo() {
  local name="$1"; shift
  if [ "$list_only" -eq 1 ]; then
    echo "  [步骤] $name"
    return
  fi
  step "$name"
  "$@"
}

# ───────────────────────── false-sharing ─────────────────────────

demo_false_sharing() {
  if [ "$list_only" -ne 1 ]; then
    ( cd "$D" && run make )
  fi

  for t in 1 2 4 8; do
    if [ "$list_only" -eq 1 ]; then
      echo "  [步骤]   threads=$t  ./false_sharing 10 $t"
    else
      ( cd "$D" && run ./false_sharing 10 $t )
    fi
  done

  # perf c2c 抓伪共享证据（HITM%）
  if [ "$list_only" -eq 1 ]; then
    echo "  [步骤]   perf c2c record/report（threads=4，需 --perf + root + Linux）"
    return
  fi
  if [ "$IS_LINUX" -ne 1 ]; then skip "perf c2c 需要 Linux（当前非 Linux）"; return 1; fi
  if [ "$DO_PERF" -ne 1 ]; then skip "perf c2c（未加 --perf 参数）"; return 1; fi
  if [ "$IS_ROOT" -ne 1 ]; then skip "perf c2c 需要 root，请用 sudo bash run_false_sharing.sh --perf"; return 1; fi
  ( cd "$D" && run sudo perf c2c record -a -- ./false_sharing 10 4 \; perf c2c report )
}

run_demo "false-sharing: 伪共享（threads=1/2/4/8 + 可选 perf c2c）" demo_false_sharing

# ───────────────────────── 完成 ─────────────────────────
if [ "$list_only" -eq 1 ]; then
  echo
  echo "以上为 false-sharing 实验步骤。去掉 --list 实际运行；加 --perf 并 sudo 跑 perf c2c。"
  exit 0
fi

echo
echo "============================================================"
echo " false-sharing 实验跑完。"
echo " 日志: $LOG"
echo " 提示: 加 --perf 并 sudo 运行可补跑 perf c2c 抓伪共享 HITM%。"
echo "============================================================"
