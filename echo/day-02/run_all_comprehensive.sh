#!/bin/bash
# run_all_comprehensive.sh — Day 2 全量实验一键重跑（含待做实验）
#
# 用法：
#   bash run_all_comprehensive.sh          # 全部实验（约 30-40 分钟）
#   bash run_all_comprehensive.sh --quick  # 快速模式（10 分钟）
#
# 新增实验（vs run_all.sh）：
#   - LT 纯范式版（echo-epoll-lt-pure-server）accept 无循环
#   - 并行完整 syscall 统计（strace -c -e all + bench.sh 100 并发）
#   - 瞬态失败系统化复现（drop_caches 跑前/跑后对比）
#   - MP worker 连接分布
#   - bench.sh 并发 strace 完整版（非仅 epoll_wait）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ---- 机器自适应配置 ----
IP="127.0.0.1"
NCPU=$(nproc)
PORT=9988

# 4 核机器：MP workers=4，并发基准适当降低
if [ "$NCPU" -le 4 ]; then
    MP_WORKERS=4
    SWEEP_CONC_MAX=100
    LONG_REQUESTS=10000
else
    MP_WORKERS=8
    SWEEP_CONC_MAX=200
    LONG_REQUESTS=10000
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_DIR="results_comprehensive_${TIMESTAMP}"
mkdir -p "$RESULT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }
section(){ echo -e "\n${CYAN}══════════════════════════════════════════════${NC}\n${CYAN}  $*${NC}\n${CYAN}══════════════════════════════════════════════${NC}"; }
warn()   { echo -e "${YELLOW}[$(date +%H:%M:%S)] WARN${NC} $*"; }
err()    { echo -e "${RED}[$(date +%H:%M:%S)] ERR${NC} $*"; }

# ---- 系统信息 ----
collect_system_info() {
    log "采集系统信息（${NCPU} 核）..."
    {
        echo "=== 系统信息 ==="
        echo "时间: $(date)"
        echo "主机: $(hostname)"
        echo "内核: $(uname -r)"
        echo "CPU: $(nproc) 核"
        echo "CPU 型号: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
        echo "内存: $(free -h | awk '/Mem:/{print $2}')"
        echo ""
        echo "=== 网络参数 ==="
        echo "tcp_tw_reuse: $(cat /proc/sys/net/ipv4/tcp_tw_reuse 2>/dev/null || echo 'N/A')"
        echo "tcp_fin_timeout: $(cat /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null || echo 'N/A')"
        echo "本地端口范围: $(cat /proc/sys/net/ipv4/ip_local_port_range)"
        echo "tcp_tw_recycle: $(cat /proc/sys/net/ipv4/tcp_tw_recycle 2>/dev/null || echo 'N/A (>=4.12 removed)')"
        echo ""
        echo "=== 内核参数（TIME-WAIT 相关）==="
        sysctl net.ipv4.tcp_fin_timeout net.ipv4.tcp_tw_reuse net.ipv4.ip_local_port_range 2>/dev/null
    } > "$RESULT_DIR/00_system_info.txt"
}

# ---- 编译 ----
compile_all() {
    log "编译所有目标（含 LT-PURE）..."
    mkdir -p bin

    # 编译原有目标
    make clean > /dev/null 2>&1 || true

    # 单独编译每个目标，方便定位编译错误
    local all_ok=true
    for src in echo-epoll-lt-server echo-epoll-server echo-mp-server echo-bench; do
        if gcc -O0 -g -Wall -Wextra -o "bin/${src}" "${src}.c" 2>&1; then
            log "  ✓ bin/${src}"
        else
            err "  ✗ bin/${src} 编译失败"
            all_ok=false
        fi
    done

    # 编译 LT-PURE
    if gcc -O0 -g -Wall -Wextra -o "bin/echo-epoll-lt-pure-server" "echo-epoll-lt-pure-server.c" 2>&1; then
        log "  ✓ bin/echo-epoll-lt-pure-server"
    else
        err "  ✗ bin/echo-epoll-lt-pure-server 编译失败"
        all_ok=false
    fi

    if ! $all_ok; then
        err "编译失败，退出"
        exit 1
    fi

    log "编译完成"
}

# ---- 工具函数 ----
port_ready() {
    local port="$1"
    for i in $(seq 1 20); do
        if ss -tlnp 2>/dev/null | grep -q ":$port "; then
            return 0
        fi
        sleep 0.2
    done
    return 1
}

start_server() {
    local name="$1"
    local port="$2"
    local pidfile="$3"

    case "$name" in
        lt)         ./bin/echo-epoll-lt-server & ;;
        et)         ./bin/echo-epoll-server & ;;
        mp)         ./bin/echo-mp-server "$MP_WORKERS" & ;;
        lt-pure)    ./bin/echo-epoll-lt-pure-server & ;;
        *)          err "未知服务器: $name"; return 1 ;;
    esac
    local pid=$!

    if port_ready "$port"; then
        log "  $name 启动 (pid=$pid)"
        echo "$pid" > "$pidfile"
    else
        err "  $name 启动超时"
        kill $pid 2>/dev/null || true
        return 1
    fi
}

stop_server() {
    local pidfile="$1"
    local name="$2"
    if [ -f "$pidfile" ]; then
        local pid=$(cat "$pidfile")
        kill $pid 2>/dev/null || true
        wait $pid 2>/dev/null || true
        rm -f "$pidfile"
        log "  $name 已停止"
    fi
}

# 确保端口干净
ensure_port_free() {
    local port="$1"
    sleep 1
    # 杀掉可能残留的进程
    local pids=$(ss -tlnp 2>/dev/null | grep ":$port " | sed -n 's/.*pid=\([0-9]*\).*/\1/p' | sort -u)
    for pid in $pids; do
        kill $pid 2>/dev/null || true
    done
    sleep 1
}

# 同步 page cache（瞬态失败实验用）
sync_caches() {
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    log "  page cache 已刷新 (drop_caches)"
}

# ============================================
#  M. 辅助：等待 TIME-WAIT 自然回收
# ============================================
wait_tw_clean() {
    local target=${1:-0}
    local waited=0
    local max_wait=65
    while [ $waited -lt $max_wait ]; do
        local tw=$(ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)
        if [ "$tw" -le "$target" ]; then
            log "  TIME-WAIT 清理到 $tw (目标 $target)"
            return 0
        fi
        sleep 5
        waited=$((waited + 5))
    done
    warn "  TIME-WAIT 仍在 ($(ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l))，继续实验"
}

# ============================================
#  A. 短跑：100 连接 × 1 轮（echo-bench 串行）
# ============================================
run_short_bench() {
    section "A. 短跑：100 连接 × 1 轮（LT / ET / MP / LT-PURE）"
    local out="$RESULT_DIR/A_short_bench.txt"

    {
        echo "=== 短跑测试 (echo-bench 100 1) ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        local modes="lt et mp lt-pure"
        for mode in $modes; do
            local pidfile="$RESULT_DIR/.pid_${mode}"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"

            local sname
            case $mode in
                lt)      sname="echo-epoll-lt-server";;
                et)      sname="echo-epoll-server";;
                mp)      sname="echo-mp-server(${MP_WORKERS}w)";;
                lt-pure) sname="echo-epoll-lt-pure-server";;
            esac

            echo "--- ${sname} (100×1) ---"
            for run in 1 2 3; do
                echo "Run $run:"
                ./bin/echo-bench "$IP" "$PORT" 100 1 2>&1
                sleep 1
            done
            echo ""

            stop_server "$pidfile" "$mode"
            sleep 2
        done
    } | tee "$out"
    log "短跑完成 → $out"
}

# ============================================
#  B. 长跑：10000 请求（100 连接 × 100 轮）
# ============================================
run_long_bench() {
    section "B. 长跑：10000 req (LT / ET / LT-PURE)"
    local out="$RESULT_DIR/B_long_bench.txt"

    {
        echo "=== 长跑测试 (echo-bench 100 100 = ${LONG_REQUESTS} req) ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        local modes="lt et lt-pure"
        for mode in $modes; do
            # 长跑前等 TIME-WAIT 回收
            wait_tw_clean 0
            local pidfile="$RESULT_DIR/.pid_${mode}_long"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"

            local sname
            case $mode in
                lt)      sname="echo-epoll-lt-server";;
                et)      sname="echo-epoll-server";;
                lt-pure) sname="echo-epoll-lt-pure-server";;
            esac

            echo "=== ${sname} (100×100 = ${LONG_REQUESTS} req) ==="
            local before_tw=$(ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)
            echo "跑前 TIME-WAIT: $before_tw"

            for run in 1 2 3; do
                echo "====== Run $run ======"
                ./bin/echo-bench "$IP" "$PORT" 100 100 2>&1
                echo ""
                sleep 2
            done

            local after_tw=$(ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)
            echo "跑后 TIME-WAIT: $after_tw"
            echo ""

            stop_server "$pidfile" "$mode"
            sleep 3
        done
    } | tee "$out"
    log "长跑完成 → $out"
}

# ============================================
#  C. bench.sh 并发测试
# ============================================
run_bench_sh() {
    section "C. bench.sh 并发测试（100 并发 nc &）"
    local out="$RESULT_DIR/C_bench_sh.txt"

    {
        echo "=== bench.sh 并发测试 (100 nc &) ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        local modes="lt et mp lt-pure"
        for mode in $modes; do
            wait_tw_clean 0
            local pidfile="$RESULT_DIR/.pid_${mode}_benchsh"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"

            local sname
            case $mode in
                lt)      sname="echo-epoll-lt-server";;
                et)      sname="echo-epoll-server";;
                mp)      sname="echo-mp-server(${MP_WORKERS}w)";;
                lt-pure) sname="echo-epoll-lt-pure-server";;
            esac

            echo "--- ${sname} (bench.sh 100 并发 × 5 轮) ---"
            local before_tw=$(ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)
            echo "跑前 TIME-WAIT: $before_tw"

            for run in 1 2 3 4 5; do
                echo "====== Run $run ======"
                bash bench.sh "$IP" "$PORT" 100 2>&1
                local tw=$(ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)
                echo "TIME-WAIT after run $run: $tw"
                sleep 1
            done
            echo ""

            stop_server "$pidfile" "$mode"
            sleep 2
        done
    } | tee "$out"
    log "bench.sh 并发完成 → $out"
}

# ============================================
#  D. pidstat CPU 监控
# ============================================
run_pidstat() {
    section "D. pidstat CPU 监控（LT / ET / LT-PURE）"
    local out="$RESULT_DIR/D_pidstat.txt"

    {
        echo "=== pidstat CPU 监控 ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        local modes="lt et lt-pure"
        for mode in $modes; do
            wait_tw_clean 0
            local pidfile="$RESULT_DIR/.pid_${mode}_pidstat"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"
            local server_pid=$(cat "$pidfile")

            local sname
            case $mode in
                lt)      sname="echo-epoll-lt";;
                et)      sname="echo-epoll";;
                lt-pure) sname="echo-epoll-lt-pure";;
            esac

            echo "--- ${sname} pidstat ---"
            pidstat -u -p "$server_pid" 1 > "$RESULT_DIR/pidstat_${mode}_raw.txt" 2>&1 &
            local pidstat_pid=$!
            sleep 1

            ./bin/echo-bench "$IP" "$PORT" 100 100 > /dev/null 2>&1
            sleep 3
            kill $pidstat_pid 2>/dev/null || true
            wait $pidstat_pid 2>/dev/null || true

            echo ""
            echo "--- pidstat 原始输出 ---"
            cat "$RESULT_DIR/pidstat_${mode}_raw.txt"
            echo ""

            stop_server "$pidfile" "$mode"
        done
    } | tee "$out"
    log "pidstat 完成 → $out"
}

# ============================================
#  E. strace -c -e epoll_wait（串行长跑）
# ============================================
run_strace_epoll() {
    section "E. strace -c -e epoll_wait（串行 10000 req）"
    local out="$RESULT_DIR/E_strace_epoll.txt"

    {
        echo "=== strace -c -e epoll_wait（echo-bench 串行 10000 req） ==="
        echo "时间: $(date)"
        echo ""

        local modes="lt et lt-pure"
        for mode in $modes; do
            wait_tw_clean 0
            local pidfile="$RESULT_DIR/.pid_${mode}_strace_e"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"
            local server_pid=$(cat "$pidfile")

            local sname
            case $mode in
                lt)      sname="echo-epoll-lt";;
                et)      sname="echo-epoll";;
                lt-pure) sname="echo-epoll-lt-pure";;
            esac

            echo "--- ${sname} strace -c -e epoll_wait ---"
            strace -c -e epoll_wait -p "$server_pid" -o "$RESULT_DIR/strace_epoll_${mode}.txt" &
            local strace_pid=$!
            sleep 0.5

            ./bin/echo-bench "$IP" "$PORT" 100 100 > /dev/null 2>&1
            sleep 0.5
            kill -INT $strace_pid 2>/dev/null || true
            wait $strace_pid 2>/dev/null || true

            echo "=== strace 结果 ==="
            cat "$RESULT_DIR/strace_epoll_${mode}.txt"
            echo ""

            stop_server "$pidfile" "$mode"
        done
    } | tee "$out"
    log "strace epoll_wait 完成 → $out"
}

# ============================================
#  F. strace -c 完整 syscall（串行长跑）
# ============================================
run_strace_full() {
    section "F. strace -c 完整 syscall 统计（串行 10000 req）"
    local out="$RESULT_DIR/F_strace_full.txt"

    {
        echo "=== strace -c 完整 syscall（echo-bench 串行 10000 req） ==="
        echo "时间: $(date)"
        echo ""

        local modes="lt et lt-pure"
        for mode in $modes; do
            wait_tw_clean 0
            local pidfile="$RESULT_DIR/.pid_${mode}_strace_f"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"
            local server_pid=$(cat "$pidfile")

            local sname
            case $mode in
                lt)      sname="echo-epoll-lt";;
                et)      sname="echo-epoll";;
                lt-pure) sname="echo-epoll-lt-pure";;
            esac

            echo "--- ${sname} strace -c (全 syscall) ---"
            strace -c -p "$server_pid" -o "$RESULT_DIR/strace_full_${mode}.txt" &
            local strace_pid=$!
            sleep 0.5

            ./bin/echo-bench "$IP" "$PORT" 100 100 > /dev/null 2>&1
            sleep 0.5
            kill -INT $strace_pid 2>/dev/null || true
            wait $strace_pid 2>/dev/null || true

            echo "=== strace 结果 ==="
            cat "$RESULT_DIR/strace_full_${mode}.txt"
            echo ""

            stop_server "$pidfile" "$mode"
        done
    } | tee "$out"
    log "strace 完整 syscall 完成 → $out"
}

# ============================================
#  G. strace -c -e epoll_wait（bench.sh 并行）— ★ 核心实验 ★
# ============================================
run_strace_bench_sh_epoll() {
    section "G. strace -c -e epoll_wait（bench.sh 100 并发）"
    local out="$RESULT_DIR/G_strace_bench_sh_epoll.txt"

    {
        echo "=== strace -c -e epoll_wait（bench.sh 100 并发 × 3 次 = 300 总并发） ==="
        echo "时间: $(date)"
        echo ""

        local modes="lt et"
        for mode in $modes; do
            wait_tw_clean 0
            local pidfile="$RESULT_DIR/.pid_${mode}_strace_g"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"
            local server_pid=$(cat "$pidfile")

            local sname
            case $mode in
                lt) sname="echo-epoll-lt";;
                et) sname="echo-epoll";;
            esac

            echo "--- ${sname} strace -c -e epoll_wait（bench.sh 累计 300 并发） ---"
            strace -c -e epoll_wait -p "$server_pid" -o "$RESULT_DIR/strace_bench_sh_epoll_${mode}.txt" &
            local strace_pid=$!
            sleep 0.5

            for i in 1 2 3; do
                bash bench.sh "$IP" "$PORT" 100 > /dev/null 2>&1
                sleep 1
            done

            sleep 0.5
            kill -INT $strace_pid 2>/dev/null || true
            wait $strace_pid 2>/dev/null || true

            echo "=== strace 结果 ==="
            cat "$RESULT_DIR/strace_bench_sh_epoll_${mode}.txt"
            echo ""

            stop_server "$pidfile" "$mode"
            sleep 1
        done
    } | tee "$out"
    log "strace bench.sh epoll_wait 并行完成 → $out"
}

# ============================================
#  H. strace -c 完整 syscall（bench.sh 并行）— ★ 核心新增实验 ★
# ============================================
run_strace_bench_sh_full() {
    section "H. strace -c 完整 syscall（bench.sh 100 并发）— ★ 新增 ★"
    local out="$RESULT_DIR/H_strace_bench_sh_full.txt"

    {
        echo "=== strace -c 完整 syscall（bench.sh 100 并发 × 3 次 = 300 总并发） ==="
        echo "目的: 定位并行下 LT epoll_wait 方差根因"
        echo "时间: $(date)"
        echo ""

        local modes="lt et"
        for mode in $modes; do
            wait_tw_clean 0
            local pidfile="$RESULT_DIR/.pid_${mode}_strace_h"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"
            local server_pid=$(cat "$pidfile")

            local sname
            case $mode in
                lt) sname="echo-epoll-lt";;
                et) sname="echo-epoll";;
            esac

            echo "--- ${sname} strace -c 完整 syscall（bench.sh 100 并发） ---"
            strace -c -p "$server_pid" -o "$RESULT_DIR/strace_bench_sh_full_${mode}.txt" &
            local strace_pid=$!
            sleep 0.5

            for i in 1 2 3; do
                bash bench.sh "$IP" "$PORT" 100 > /dev/null 2>&1
                sleep 1
            done

            sleep 0.5
            kill -INT $strace_pid 2>/dev/null || true
            wait $strace_pid 2>/dev/null || true

            echo "=== strace 完整 syscall 结果 ==="
            cat "$RESULT_DIR/strace_bench_sh_full_${mode}.txt"
            echo ""

            stop_server "$pidfile" "$mode"
            sleep 1
        done
    } | tee "$out"
    log "strace bench.sh 完整 syscall 并行完成 → $out"
}

# ============================================
#  I. 并发 sweep（bench.sh 10-100）
# ============================================
run_concurrency_sweep() {
    section "I. 并发 sweep（bench.sh 10/20/30/40/50/60/100）"
    local out="$RESULT_DIR/I_concurrency_sweep.txt"

    {
        echo "=== bench.sh 并发 sweep ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        local modes="lt et mp"
        for mode in $modes; do
            wait_tw_clean 0
            local pidfile="$RESULT_DIR/.pid_${mode}_sweep"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"

            local sname
            case $mode in
                lt) sname="echo-epoll-lt-server";;
                et) sname="echo-epoll-server";;
                mp) sname="echo-mp-server(${MP_WORKERS}w)";;
            esac

            echo "=== ${sname} ==="
            for conc in 10 20 30 40 50 60 100; do
                echo "--- 并发=$conc ---"
                for run in 1 2 3; do
                    local start_ns=$(date +%s%N)
                    bash bench.sh "$IP" "$PORT" "$conc" > /dev/null 2>&1
                    local end_ns=$(date +%s%N)
                    local elapsed=$(( (end_ns - start_ns) / 1000000 ))
                    local qps=0
                    [ $elapsed -gt 0 ] && qps=$(( conc * 1000 / elapsed ))
                    echo "  Run $run: ${elapsed}ms, QPS≈$qps"
                    sleep 1
                done
            done
            echo ""

            stop_server "$pidfile" "$mode"
            sleep 2
        done
    } | tee "$out"
    log "并发 sweep 完成 → $out"
}

# ============================================
#  J. LT-PURE vs LT 直接对比（strace 精确分析）
# ============================================
run_lt_pure_vs_lt_strace() {
    section "J. LT-PURE vs LT 直接对比 — strace 精确分析"
    local out="$RESULT_DIR/J_lt_pure_vs_lt_strace.txt"

    {
        echo "=== LT-PURE vs LT strace -c 完整对比 ==="
        echo "目的: 量化 accept 循环去除后的 syscall 结构变化"
        echo "预期: LT-PURE 比 LT 少 ~10000 次 accept(EAGAIN) + 少 ~10000 次 fcntl"
        echo "时间: $(date)"
        echo ""

        local modes="lt lt-pure"
        for mode in $modes; do
            wait_tw_clean 0
            local pidfile="$RESULT_DIR/.pid_${mode}_strace_j"
            ensure_port_free $PORT

            start_server "$mode" "$PORT" "$pidfile"
            local server_pid=$(cat "$pidfile")

            local sname
            case $mode in
                lt)      sname="echo-epoll-lt";;
                lt-pure) sname="echo-epoll-lt-pure";;
            esac

            echo "=== ${sname} strace -c 完整（10000 req） ==="
            strace -c -p "$server_pid" -o "$RESULT_DIR/strace_lt_pure_${mode}.txt" &
            local strace_pid=$!
            sleep 0.5

            ./bin/echo-bench "$IP" "$PORT" 100 100 > /dev/null 2>&1
            sleep 0.5
            kill -INT $strace_pid 2>/dev/null || true
            wait $strace_pid 2>/dev/null || true

            echo "=== strace 结果 ==="
            cat "$RESULT_DIR/strace_lt_pure_${mode}.txt"
            echo ""

            stop_server "$pidfile" "$mode"
            sleep 2
        done

        echo ""
        echo "=== 对比总结 ==="
        echo "LT-PURE key metrics:"
        if [ -f "$RESULT_DIR/strace_lt_pure_lt-pure.txt" ]; then
            echo "--- LT-PURE ---"
            grep -E "accept|epoll|fcntl|close|read|write|total" "$RESULT_DIR/strace_lt_pure_lt-pure.txt" 2>/dev/null || true
        fi
        if [ -f "$RESULT_DIR/strace_lt_pure_lt.txt" ]; then
            echo "--- LT (baseline) ---"
            grep -E "accept|epoll|fcntl|close|read|write|total" "$RESULT_DIR/strace_lt_pure_lt.txt" 2>/dev/null || true
        fi
    } | tee "$out"
    log "LT-PURE vs LT strace 对比完成 → $out"
}

# ============================================
#  K. 瞬态失败系统化复现（drop_caches）
# ============================================
run_transient_failure() {
    section "K. 瞬态失败系统化复现（drop_caches + 5 跑对比）"
    local out="$RESULT_DIR/K_transient_failure.txt"

    {
        echo "=== 瞬态失败系统化复现 ==="
        echo "目的: 确认冷启动 vs 偶发的边界"
        echo "方法: 跑前 sync && drop_caches，5 跑对比 Run 1 vs 2-5"
        echo "时间: $(date)"
        echo ""

        # 使用 LT 版（最稳定）作为对照
        local mode="lt"
        local sname="echo-epoll-lt-server"

        # --- 条件 A: 冷启动（drop_caches） ---
        echo "========== 条件 A: 冷启动（drop_caches 后首跑） =========="
        wait_tw_clean 0
        sync_caches
        local pidfile="$RESULT_DIR/.pid_transient_a"
        ensure_port_free $PORT

        start_server "$mode" "$PORT" "$pidfile"

        for run in 1 2 3 4 5; do
            echo "====== Run $run ======"
            ./bin/echo-bench "$IP" "$PORT" 100 100 2>&1
            echo ""
            sleep 2
        done

        stop_server "$pidfile" "transient-a"
        sleep 3

        # --- 条件 B: 热启动（无 drop_caches） ---
        echo ""
        echo "========== 条件 B: 热启动（正常连续 5 跑） =========="
        wait_tw_clean 0
        local pidfile="$RESULT_DIR/.pid_transient_b"
        ensure_port_free $PORT

        start_server "$mode" "$PORT" "$pidfile"

        for run in 1 2 3 4 5; do
            echo "====== Run $run ======"
            ./bin/echo-bench "$IP" "$PORT" 100 100 2>&1
            echo ""
            sleep 2
        done

        stop_server "$pidfile" "transient-b"
        sleep 3

        # --- 条件 C: 冷启动 × 2 次（验证可重现性） ---
        echo ""
        echo "========== 条件 C: 冷启动 ×2（验证可重现性） =========="
        wait_tw_clean 0
        sync_caches
        local pidfile="$RESULT_DIR/.pid_transient_c"
        ensure_port_free $PORT

        start_server "$mode" "$PORT" "$pidfile"

        for run in 1 2 3 4 5; do
            echo "====== Run $run ======"
            ./bin/echo-bench "$IP" "$PORT" 100 100 2>&1
            echo ""
            sleep 2
        done

        stop_server "$pidfile" "transient-c"
    } | tee "$out"
    log "瞬态失败复现完成 → $out"
}

# ============================================
#  L. MP worker 连接分布
# ============================================
run_mp_worker_distribution() {
    section "L. MP worker 连接分布（SO_REUSEPORT 哈希均匀性）"
    local out="$RESULT_DIR/L_mp_worker_distribution.txt"

    {
        echo "=== MP worker 连接分布 ==="
        echo "目的: 验证 SO_REUSEPORT 哈希均匀性"
        echo "方法: bench.sh 高并发下观察 worker accept 计数"
        echo "时间: $(date)"
        echo ""

        wait_tw_clean 0
        local pidfile="$RESULT_DIR/.pid_mp_dist"
        ensure_port_free $PORT

        # 启动 MP 服务器，输出 worker pid
        ./bin/echo-mp-server "$MP_WORKERS" > "$RESULT_DIR/mp_server_output.txt" 2>&1 &
        local master_pid=$!
        sleep 1

        if ! port_ready "$PORT"; then
            err "MP 服务器启动失败"
            echo "$master_pid" > "$pidfile"
            stop_server "$pidfile" "mp-dist"
            return
        fi

        echo "Master PID: $master_pid"
        echo "Worker PIDs: $(pgrep -P $master_pid | tr '\n' ' ')"
        echo ""

        # 用 echo-bench 建立 200 连接，看每个 worker 分布
        echo "--- echo-bench 200 连接串行 ---"
        local worker_pids=$(pgrep -P $master_pid)

        # 记录跑前每个 worker 的 fd 数
        echo "跑前 worker fd 数:"
        for pid in $worker_pids; do
            echo "  Worker $pid: $(ls /proc/$pid/fd 2>/dev/null | wc -l) fd"
        done

        ./bin/echo-bench "$IP" "$PORT" 200 1 > /dev/null 2>&1
        sleep 2

        echo ""
        echo "跑后 worker fd 数:"
        for pid in $worker_pids; do
            echo "  Worker $pid: $(ls /proc/$pid/fd 2>/dev/null | wc -l) fd"
        done
        echo ""

        # bench.sh 100 并发
        echo "--- bench.sh 100 并发 ---"
        echo "跑前 worker fd 数:"
        for pid in $worker_pids; do
            echo "  Worker $pid: $(ls /proc/$pid/fd 2>/dev/null | wc -l) fd"
        done

        bash bench.sh "$IP" "$PORT" 100 > /dev/null 2>&1
        sleep 3

        echo ""
        echo "跑后 worker fd 数:"
        for pid in $worker_pids; do
            echo "  Worker $pid: $(ls /proc/$pid/fd 2>/dev/null | wc -l) fd"
        done

        # 额外: strace 观察各 worker accept() 调用次数
        echo ""
        echo "--- strace -c accept 各 worker（bench.sh 100 并发） ---"
        for pid in $worker_pids; do
            strace -c -e accept -p "$pid" -o "$RESULT_DIR/strace_mp_accept_${pid}.txt" &
            local spid=$!
            sleep 0.2
            bash bench.sh "$IP" "$PORT" 100 > /dev/null 2>&1
            sleep 0.5
            kill -INT $spid 2>/dev/null || true
            wait $spid 2>/dev/null || true
            echo "Worker $pid accept 统计:"
            cat "$RESULT_DIR/strace_mp_accept_${pid}.txt"
            echo ""
            sleep 2
        done

        echo "$master_pid" > "$pidfile"
        stop_server "$pidfile" "mp-dist"
    } | tee "$out"
    log "MP worker 分布完成 → $out"
}

# ============================================
#  快速模式（仅核心对比实验）
# ============================================
run_quick() {
    section "快速模式（核心对比实验，约 10 分钟）"
    collect_system_info
    compile_all
    echo ""

    # 仅跑关键对比实验
    run_short_bench
    echo ""
    run_lt_pure_vs_lt_strace
    echo ""
    run_strace_bench_sh_full
    echo ""
    run_transient_failure
}

# ============================================
#  主流程
# ============================================
main() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  Day 2 Echo 全量实验 — 综合重跑               ║"
    echo "║  机器: $(nproc) 核 / $(free -h | awk '/Mem:/{print $2}') 内存                ║"
    echo "║  结果目录: $RESULT_DIR                        ║"
    echo "║  模式: ${1:-all}                              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    collect_system_info
    compile_all
    echo ""

    local mode="${1:-all}"

    case "$mode" in
        --quick)
            run_quick
            ;;
        all)
            # A. 短跑
            wait_tw_clean 0
            run_short_bench
            echo ""

            # J. LT-PURE vs LT strace 对比
            wait_tw_clean 0
            run_lt_pure_vs_lt_strace
            echo ""

            # B. 长跑
            wait_tw_clean 0
            run_long_bench
            echo ""

            # C. bench.sh 并发
            wait_tw_clean 0
            run_bench_sh
            echo ""

            # D. pidstat
            wait_tw_clean 0
            run_pidstat
            echo ""

            # E. strace epoll_wait 串行
            wait_tw_clean 0
            run_strace_epoll
            echo ""

            # F. strace 完整 syscall 串行
            wait_tw_clean 0
            run_strace_full
            echo ""

            # G. strace epoll_wait 并行
            wait_tw_clean 0
            run_strace_bench_sh_epoll
            echo ""

            # H. strace 完整 syscall 并行（★ 核心新增）
            wait_tw_clean 0
            run_strace_bench_sh_full
            echo ""

            # I. 并发 sweep
            wait_tw_clean 0
            run_concurrency_sweep
            echo ""

            # K. 瞬态失败系统化复现
            wait_tw_clean 0
            run_transient_failure
            echo ""

            # L. MP worker 连接分布
            wait_tw_clean 0
            run_mp_worker_distribution
            ;;
        *)
            echo "用法: $0 [--quick]"
            echo "  无参数 = 全部实验（约 30-40 分钟）"
            echo "  --quick = 快速模式（约 10 分钟，仅核心对比）"
            exit 1
            ;;
    esac

    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  全部实验完成！                               ║"
    echo "║  结果目录: $RESULT_DIR                        ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    log "结果文件列表:"
    ls -la "$RESULT_DIR/"
}

main "$@"
