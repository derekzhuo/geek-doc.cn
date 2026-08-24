#!/usr/bin/env bash
# run_experiments.sh —— 一键跑完 syscall-trace 全部实验
#
# 覆盖 README 第 3 章所有数据点：
#   3.2 实验数据：三模式 perf trace -s 汇总 + 特定 syscall 观察
#   3.3 与 strace 对比：time 基线 / perf trace / strace -c 计时
#
# 用法：  bash run_experiments.sh
# 结果：  同时打印到屏幕并写入 experiment-<时间戳>.log
set -u

cd "$(dirname "$0")" || exit 1

TARGET=syscall_trace
LOG="experiment-$(date +%Y%m%d-%H%M%S).log"

echo "日志将写入: $LOG"
: > "$LOG"

step() {
  echo
  echo "##################################################"
  echo "# $1"
  echo "##################################################"
  echo "[$1]" >> "$LOG"
}

# 检查命令是否存在；不存在则提示并跳过（返回 1）
need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "  [跳过] 未找到命令 '$1'（可安装后重试）"
    return 1
  fi
  return 0
}

# 非 root 时 perf trace 常因 perf_event_paranoid 失败，给个友好提示
if [ "$(id -u)" -ne 0 ]; then
  echo "[提示] 当前非 root；perf trace 可能需要 root 或 CAP_PERFMON，"
  echo "        若报错可尝试:  sudo bash run_experiments.sh"
fi

# 0. 编译
step "0. 编译 $TARGET"
make "$TARGET" || { echo "编译失败，退出"; exit 1; }

# 1. 基线计时（无追踪）—— 对应 3.3 表第一行
step "1. 基线计时  time ./$TARGET io"
{ time ./$TARGET io ; } 2>&1 | tee -a "$LOG"

# 2. 三模式 perf trace -s 汇总 —— 对应 3.2 数据记录表三行
for m in io lock sleep; do
  if need perf; then
    step "2. perf trace -s 汇总（${m} 模式）"
    perf trace -s ./$TARGET "$m" 2>&1 | tee -a "$LOG"
  fi
done

# 3. 特定 syscall 观察（演示用）
if need perf; then
  step "3a. perf trace -e write ./$TARGET io"
  perf trace -e write ./$TARGET io 2>&1 | tee -a "$LOG"
  step "3b. perf trace -e futex ./$TARGET lock"
  perf trace -e futex ./$TARGET lock 2>&1 | tee -a "$LOG"
fi

# 4. 与 strace 对比计时 —— 对应 3.3 表
if need perf; then
  step "4a. perf trace -s 计时  time perf trace -s ./$TARGET io"
  { time perf trace -s ./$TARGET io ; } 2>&1 | tee -a "$LOG"
fi
if need strace; then
  step "4b. strace -c 计时  time strace -c ./$TARGET io"
  { time strace -c ./$TARGET io ; } 2>&1 | tee -a "$LOG"
fi

echo
echo "===== 全部实验完成，结果见: $LOG ====="
