#!/bin/bash
# run_perf_test.sh —— PMU 直通环境下的自动化性能对比测试
#
# 用法:
#   chmod +x run_perf_test.sh
#   ./run_perf_test.sh          # 自动检测 PMU 是否可用，走 cycles 或 cpu-clock
#   ./run_perf_test.sh force    # 强制使用 cycles:upp（PMU 不可用时报错退出）
#   ./run_perf_test.sh fallback # 强制使用 cpu-clock（即使有 PMU）
#
# 输出文件:
#   results/pmu_check.txt         PMU 可用性检查
#   results/throughput.txt        吞吐量原始数据
#   results/perf_stat_base.txt    基线版 perf stat
#   results/perf_stat_opt.txt     优化版 perf stat
#   results/perf_diff.txt         perf diff 对比
#   results/perf_report_base.txt  基线版 perf report
#   results/perf_report_opt.txt   优化版 perf report
#   results/perf_bench.txt        系统微基准
#   results/summary.txt           汇总报告
#   results/perf_base.data        基线版 perf.data
#   results/perf_opt.data         优化版 perf.data
#
# 更新时间：2026-08-06

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/results"
BIN="${SCRIPT_DIR}/perf_bench_diff"

# ── 颜色 ─────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── 参数解析 ─────────────────────────────────────────────────
MODE="${1:-auto}"

# ── 准备工作 ─────────────────────────────────────────────────
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   PMU 直通环境 —— 自动化性能对比测试脚本                     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

mkdir -p "$RESULTS_DIR"

# 编译
echo -e "${BLUE}[1/8]${NC} 编译被测程序..."
cd "$SCRIPT_DIR"
make clean > /dev/null 2>&1 || true
make all
echo -e "  ${GREEN}✓${NC} 编译完成: $BIN"
echo ""

# ── 检查 PMU 可用性 ─────────────────────────────────────────
echo -e "${BLUE}[2/8]${NC} 检查 PMU 可用性..."

PMU_AVAILABLE=false
PMU_EVENT=""

# 方法1: 尝试用 perf stat 跑一个 cycles 事件
if perf stat -e cycles:u true 2>/dev/null; then
    PMU_AVAILABLE=true
    PMU_EVENT="cycles:u"
    PMU_EVENT_LABEL="cycles:u (硬件 PMU)"
# 方法2: 尝试 cycles:upp (user + precise)
elif perf stat -e cycles:upp true 2>/dev/null; then
    PMU_AVAILABLE=true
    PMU_EVENT="cycles:upp"
    PMU_EVENT_LABEL="cycles:upp (硬件 PMU, precise)"
# 方法3: 检查 /sys 下的 PMU 设备
elif [ -d /sys/devices/cpu/caps/pmu_name ] && [ -n "$(cat /sys/devices/cpu/caps/pmu_name 2>/dev/null || true)" ]; then
    # PMU 存在但当前用户可能没权限，尝试用 perf record -e cycles
    if perf record -e cycles -o /dev/null -- true 2>/dev/null; then
        PMU_AVAILABLE=true
        PMU_EVENT="cycles"
        PMU_EVENT_LABEL="cycles (硬件 PMU)"
    fi
fi

if $PMU_AVAILABLE; then
    echo -e "  ${GREEN}✓${NC} PMU 可用，使用事件: ${PMU_EVENT_LABEL}"
else
    echo -e "  ${YELLOW}⚠${NC} PMU 不可用"
fi

# 根据 mode 决定最终使用的事件
case "$MODE" in
    force)
        if ! $PMU_AVAILABLE; then
            echo -e "  ${RED}✗${NC} 强制 PMU 模式但 PMU 不可用，退出"
            exit 1
        fi
        FINAL_EVENT="$PMU_EVENT"
        EVENT_LABEL="$PMU_EVENT_LABEL"
        ;;
    fallback)
        FINAL_EVENT="cpu-clock"
        EVENT_LABEL="cpu-clock (软件时钟, 无 PMU)"
        ;;
    auto|*)
        if $PMU_AVAILABLE; then
            FINAL_EVENT="$PMU_EVENT"
            EVENT_LABEL="$PMU_EVENT_LABEL"
        else
            FINAL_EVENT="cpu-clock"
            EVENT_LABEL="cpu-clock (软件时钟, 降级)"
        fi
        ;;
esac

echo -e "  → 最终使用: ${GREEN}${EVENT_LABEL}${NC}"
echo ""

# 保存 PMU 信息
{
    echo "=== PMU 检查 ==="
    echo "检测时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "PMU 可用: $PMU_AVAILABLE"
    echo "使用事件: $FINAL_EVENT"
    echo "事件说明: $EVENT_LABEL"
    echo ""
    echo "=== CPU 信息 ==="
    cat /proc/cpuinfo | grep -E 'model name|cpu cores|siblings|cache size' | head -20
    echo ""
    echo "=== 内存信息 ==="
    free -h
    echo ""
    echo "=== NUMA 拓扑 ==="
    numactl --hardware 2>/dev/null || echo "(numactl 不可用)"
} > "$RESULTS_DIR/pmu_check.txt"

# ── 吞吐量测试 ───────────────────────────────────────────────
echo -e "${BLUE}[3/8]${NC} 吞吐量测试..."

# 跑 5 轮取平均
BASE_THROUGHPUTS=()
OPT_THROUGHPUTS=()

echo -n "  基线版: "
for i in $(seq 1 5); do
    out=$("$BIN" base 2>&1 | grep -oP '吞吐:\s*\K[0-9.]+')
    BASE_THROUGHPUTS+=("$out")
    echo -n "$out "
done
echo ""

echo -n "  优化版: "
for i in $(seq 1 5); do
    out=$("$BIN" opt 2>&1 | grep -oP '吞吐:\s*\K[0-9.]+')
    OPT_THROUGHPUTS+=("$out")
    echo -n "$out "
done
echo ""

# 计算平均值
calc_avg() {
    local sum=0
    local count=$#
    for v in "$@"; do
        sum=$(echo "$sum + $v" | bc -l)
    done
    echo "scale=3; $sum / $count" | bc -l
}

BASE_AVG=$(calc_avg "${BASE_THROUGHPUTS[@]}")
OPT_AVG=$(calc_avg "${OPT_THROUGHPUTS[@]}")
SPEEDUP=$(echo "scale=2; $OPT_AVG / $BASE_AVG" | bc -l)

{
    echo "=== 吞吐量测试 (5 轮平均) ==="
    echo "基线版原始数据: ${BASE_THROUGHPUTS[*]}"
    echo "基线版平均吞吐: ${BASE_AVG} 亿次访问/s"
    echo ""
    echo "优化版原始数据: ${OPT_THROUGHPUTS[*]}"
    echo "优化版平均吞吐: ${OPT_AVG} 亿次访问/s"
    echo ""
    echo "加速比: ${SPEEDUP}x"
} > "$RESULTS_DIR/throughput.txt"

echo -e "  ${GREEN}✓${NC} 基线版: ${BASE_AVG} 亿次/s  |  优化版: ${OPT_AVG} 亿次/s  |  加速比: ${SPEEDUP}x"
echo ""

# ── perf stat ────────────────────────────────────────────────
echo -e "${BLUE}[4/8]${NC} perf stat 统计..."

if $PMU_AVAILABLE; then
    # PMU 可用: 完整版（cycles + cache-misses + instructions + branches）
    echo "  → PMU 模式：完整硬件事件"
    STAT_EVENTS="cycles,instructions,cache-references,cache-misses,branch-misses,L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses"
else
    # PMU 不可用: 降级版（仅软件事件）
    echo "  → 无 PMU 模式：仅软件事件"
    STAT_EVENTS="cpu-clock,task-clock,context-switches,cpu-migrations,page-faults"
fi

echo -n "  基线版..."
perf stat -e "$STAT_EVENTS" -o "$RESULTS_DIR/perf_stat_base_raw.txt" "$BIN" base 2>/dev/null
# 格式化输出
echo "=== perf stat 基线版 (${FINAL_EVENT}) ===" > "$RESULTS_DIR/perf_stat_base.txt"
echo "事件: $STAT_EVENTS" >> "$RESULTS_DIR/perf_stat_base.txt"
cat "$RESULTS_DIR/perf_stat_base_raw.txt" >> "$RESULTS_DIR/perf_stat_base.txt"
echo "  ${GREEN}✓${NC}"

echo -n "  优化版..."
perf stat -e "$STAT_EVENTS" -o "$RESULTS_DIR/perf_stat_opt_raw.txt" "$BIN" opt 2>/dev/null
echo "=== perf stat 优化版 (${FINAL_EVENT}) ===" > "$RESULTS_DIR/perf_stat_opt.txt"
echo "事件: $STAT_EVENTS" >> "$RESULTS_DIR/perf_stat_opt.txt"
cat "$RESULTS_DIR/perf_stat_opt_raw.txt" >> "$RESULTS_DIR/perf_stat_opt.txt"
echo "  ${GREEN}✓${NC}"

rm -f "$RESULTS_DIR/perf_stat_base_raw.txt" "$RESULTS_DIR/perf_stat_opt_raw.txt"
echo ""

# ── perf record + perf diff ──────────────────────────────────
echo -e "${BLUE}[5/8]${NC} perf record & perf diff..."

echo -n "  录制基线版 (${FINAL_EVENT})..."
perf record -e "$FINAL_EVENT" -o "$RESULTS_DIR/perf_base.data" "$BIN" base 2>&1 | tail -1
echo "  ${GREEN}✓${NC}"

echo -n "  录制优化版 (${FINAL_EVENT})..."
perf record -e "$FINAL_EVENT" -o "$RESULTS_DIR/perf_opt.data" "$BIN" opt 2>&1 | tail -1
echo "  ${GREEN}✓${NC}"

echo ""
echo "  ── perf diff ──"
perf diff "$RESULTS_DIR/perf_base.data" "$RESULTS_DIR/perf_opt.data" | tee "$RESULTS_DIR/perf_diff.txt"
echo ""

# ── perf report ──────────────────────────────────────────────
echo -e "${BLUE}[6/8]${NC} perf report..."

echo -n "  基线版..."
perf report -i "$RESULTS_DIR/perf_base.data" --stdio \
    --sort comm,dso,symbol \
    --no-children \
    2>/dev/null > "$RESULTS_DIR/perf_report_base.txt"
echo "  ${GREEN}✓${NC}"

echo -n "  优化版..."
perf report -i "$RESULTS_DIR/perf_opt.data" --stdio \
    --sort comm,dso,symbol \
    --no-children \
    2>/dev/null > "$RESULTS_DIR/perf_report_opt.txt"
echo "  ${GREEN}✓${NC}"
echo ""

# ── perf bench ───────────────────────────────────────────────
echo -e "${BLUE}[7/8]${NC} perf bench 系统微基准..."

{
    echo "=== perf bench 系统微基准 ==="
    echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "── memcpy 带宽 ──"
    perf bench mem memcpy 2>&1
    echo ""
    echo "── sched pipe ──"
    perf bench sched pipe 2>&1
    echo ""
    echo "── sched messaging ──"
    perf bench sched messaging 2>&1
} > "$RESULTS_DIR/perf_bench.txt"

echo -e "  ${GREEN}✓${NC} 完成"
echo ""

# ── 汇总报告 ─────────────────────────────────────────────────
echo -e "${BLUE}[8/8]${NC} 生成汇总报告..."

# 从 perf stat 中提取关键指标
extract_stat() {
    local file="$1"
    local pattern="$2"
    grep -E "$pattern" "$file" | awk '{print $1}' | tr -d ',' | head -1 || echo "N/A"
}

BASE_CYCLES=$(extract_stat "$RESULTS_DIR/perf_stat_base.txt" 'cycles' || echo "N/A")
OPT_CYCLES=$(extract_stat "$RESULTS_DIR/perf_stat_opt.txt" 'cycles' || echo "N/A")
BASE_INSNS=$(extract_stat "$RESULTS_DIR/perf_stat_base.txt" 'instructions' || echo "N/A")
OPT_INSNS=$(extract_stat "$RESULTS_DIR/perf_stat_opt.txt" 'instructions' || echo "N/A")
BASE_IPC=$(extract_stat "$RESULTS_DIR/perf_stat_base.txt" 'insn per cycle' || echo "N/A")
OPT_IPC=$(extract_stat "$RESULTS_DIR/perf_stat_opt.txt" 'insn per cycle' || echo "N/A")
BASE_BRANCH_MISS=$(extract_stat "$RESULTS_DIR/perf_stat_base.txt" 'branch-misses' || echo "N/A")
OPT_BRANCH_MISS=$(extract_stat "$RESULTS_DIR/perf_stat_opt.txt" 'branch-misses' || echo "N/A")
BASE_CACHE_MISS=$(extract_stat "$RESULTS_DIR/perf_stat_base.txt" 'cache-misses' || echo "N/A")
OPT_CACHE_MISS=$(extract_stat "$RESULTS_DIR/perf_stat_opt.txt" 'cache-misses' || echo "N/A")

{
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              性能对比测试 —— 汇总报告                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "主机名:   $(hostname)"
    echo "内核版本: $(uname -r)"
    echo "PMU 事件: ${EVENT_LABEL}"
    echo ""
    echo "── 1. 吞吐量（5 轮平均） ──"
    echo "  基线版: ${BASE_AVG} 亿次访问/s"
    echo "  优化版: ${OPT_AVG} 亿次访问/s"
    echo "  加速比: ${SPEEDUP}x"
    echo ""
    echo "── 2. perf stat 关键指标 ──"
    echo "  指标              基线版          优化版          变化"
    echo "  ─────────────────────────────────────────────────────"
    printf "  CPU 周期          %-14s %-14s -\n" "$BASE_CYCLES" "$OPT_CYCLES"
    printf "  指令数            %-14s %-14s -\n" "$BASE_INSNS" "$OPT_INSNS"
    printf "  IPC               %-14s %-14s -\n" "$BASE_IPC" "$OPT_IPC"
    printf "  分支预测失败      %-14s %-14s -\n" "$BASE_BRANCH_MISS" "$OPT_BRANCH_MISS"
    printf "  Cache Miss        %-14s %-14s -\n" "$BASE_CACHE_MISS" "$OPT_CACHE_MISS"
    echo ""
    echo "── 3. perf diff 热点变化 ──"
    echo "  (见 results/perf_diff.txt)"
    echo ""
    echo "── 4. perf bench 系统上限 ──"
    echo "  (见 results/perf_bench.txt)"
    echo ""
    echo "── 5. 输出文件清单 ──"
    echo "  results/pmu_check.txt        PMU 可用性 + 系统信息"
    echo "  results/throughput.txt       吞吐量原始数据"
    echo "  results/perf_stat_base.txt   基线版 perf stat"
    echo "  results/perf_stat_opt.txt    优化版 perf stat"
    echo "  results/perf_diff.txt        perf diff 对比"
    echo "  results/perf_report_base.txt 基线版 perf report"
    echo "  results/perf_report_opt.txt  优化版 perf report"
    echo "  results/perf_bench.txt       系统微基准"
    echo "  results/summary.txt          本文件"
} > "$RESULTS_DIR/summary.txt"

# 打印到终端
cat "$RESULTS_DIR/summary.txt"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  全部测试完成！结果保存在 results/ 目录                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
