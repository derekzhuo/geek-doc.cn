#!/bin/bash
# run_all.sh — Day 2 全部实验一键重跑（20 核机器）
#
# 用法：
#   chmod +x run_all.sh
#   ./run_all.sh                    # 全部实验（约 15-20 分钟）
#   ./run_all.sh --short            # 仅短跑（1 分钟）
#   ./run_all.sh --long             # 仅长跑 + pidstat + strace（10 分钟）
#   ./run_all.sh --bench-sh         # 仅 bench.sh 并发（5 分钟）
#   ./run_all.sh --clean            # 清理临时文件
#
# 所有结果保存在 ./results_<timestamp>/ 目录下

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ---- 配置 ----
IP="${BENCH_IP:-127.0.0.1}"
PORT_LT=9988
PORT_ET=9988
PORT_MP=9988
CPUS="${BENCH_CPUS:-0-19}"           # 20 核，默认全用
MP_WORKERS="${MP_WORKERS:-8}"        # 多进程 worker 数（20 核建议 8/12/16）

NCPU=$(nproc)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_DIR="results_${TIMESTAMP}"
mkdir -p "$RESULT_DIR"

# ---- 颜色 ----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)] WARN${NC} $*"; }
err()  { echo -e "${RED}[$(date +%H:%M:%S)] ERR${NC} $*"; }

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
        echo "=== tcp_tw_reuse ==="
        cat /proc/sys/net/ipv4/tcp_tw_reuse
        echo ""
        echo "=== 本地端口范围 ==="
        cat /proc/sys/net/ipv4/ip_local_port_range
        echo ""
    } > "$RESULT_DIR/00_system_info.txt"
    log "系统信息已保存到 $RESULT_DIR/00_system_info.txt"
}

# ---- 编译 ----
compile_all() {
    log "编译所有目标..."
    make clean > /dev/null 2>&1 || true
    make all 2>&1 | tail -3
    log "编译完成"
}

# ---- 工具函数：启动服务端 ----
start_server() {
    local name="$1"   # lt / et / mp
    local port="$2"
    local logfile="$3"

    case "$name" in
        lt)
            taskset -c "$CPUS" ./bin/echo-epoll-lt-server &
            ;;
        et)
            taskset -c "$CPUS" ./bin/echo-epoll-server &
            ;;
        mp)
            taskset -c "$CPUS" ./bin/echo-mp-server "$MP_WORKERS" &
            ;;
    esac
    local pid=$!
    sleep 0.5

    # 等待端口就绪
    for i in $(seq 1 20); do
        if ss -tlnp 2>/dev/null | grep -q ":$port "; then
            log "  $name 服务端启动成功 (pid=$pid, port=$port)"
            echo "$pid" > "$logfile"
            return 0
        fi
        sleep 0.2
    done
    err "  $name 服务端启动超时，退出"
    kill $pid 2>/dev/null || true
    exit 1
}

stop_server() {
    local pidfile="$1"
    local name="$2"
    if [ -f "$pidfile" ]; then
        local pid=$(cat "$pidfile")
        kill $pid 2>/dev/null || true
        wait $pid 2>/dev/null || true
        rm -f "$pidfile"
        log "  $name 服务端已停止 (pid=$pid)"
    fi
}

# ============================================
#  A. 短跑：100 连接 × 1 轮（echo-bench 串行）
# ============================================
run_short_bench() {
    log "====== A. 短跑：100 连接 × 1 轮 ======"
    local out="$RESULT_DIR/A_short_bench.txt"

    {
        echo "=== 短跑测试 (echo-bench 100 1) ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        for mode in lt et mp; do
            case $mode in
                lt) port=$PORT_LT; server="echo-epoll-lt-server";;
                et) port=$PORT_ET; server="echo-epoll-server";;
                mp) port=$PORT_MP; server="echo-mp-server";;
            esac

            start_server "$mode" "$port" "$RESULT_DIR/.pid_${mode}"

            echo "--- ${server} (100×1) ---"
            for run in 1 2 3; do
                echo "Run $run:"
                ./bin/echo-bench "$IP" "$port" 100 1 2>&1
                sleep 0.5
            done
            echo ""

            stop_server "$RESULT_DIR/.pid_${mode}" "$mode"
        done
    } | tee "$out"

    log "短跑完成 → $out"
}

# ============================================
#  B. 长跑：100 连接 × 100 轮 = 10000 req（echo-bench 串行）
# ============================================
run_long_bench() {
    log "====== B. 长跑：10000 req (100×100) ======"
    local out="$RESULT_DIR/B_long_bench.txt"

    {
        echo "=== 长跑测试 (echo-bench 100 100) ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        for mode in lt et; do
            case $mode in
                lt) port=$PORT_LT; server="echo-epoll-lt-server";;
                et) port=$PORT_ET; server="echo-epoll-server";;
            esac

            start_server "$mode" "$port" "$RESULT_DIR/.pid_${mode}"

            echo "--- ${server} (100×100 = 10000 req) ---"
            for run in 1 2 3; do
                echo "====== Run $run ======"
                ./bin/echo-bench "$IP" "$port" 100 100 2>&1
                echo ""
                sleep 1
            done
            echo ""

            stop_server "$RESULT_DIR/.pid_${mode}" "$mode"
        done
    } | tee "$out"

    log "长跑完成 → $out"
}

# ============================================
#  C. bench.sh 并发测试（100 nc & 并行）
# ============================================
run_bench_sh() {
    log "====== C. bench.sh 并发测试 ======"
    local out="$RESULT_DIR/C_bench_sh.txt"

    {
        echo "=== bench.sh 并发测试 (100 nc &) ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        for mode in lt et mp; do
            case $mode in
                lt) port=$PORT_LT; server="echo-epoll-lt-server";;
                et) port=$PORT_ET; server="echo-epoll-server";;
                mp) port=$PORT_MP; server="echo-mp-server";;
            esac

            start_server "$mode" "$port" "$RESULT_DIR/.pid_${mode}"

            echo "--- ${server} (bench.sh 100 并发 × 5 轮) ---"

            # 记录跑前 TIME-WAIT 数量
            echo "跑前 TIME-WAIT: $(ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)"

            for run in 1 2 3 4 5; do
                echo "====== Run $run ======"
                bash bench.sh "$IP" "$port" 100 2>&1

                # 记录跑后 TIME-WAIT
                echo "TIME-WAIT after: $(ss -tan state time-wait 2>/dev/null | tail -n +2 | wc -l)"

                # Run 1 和 Run 2-5 之间清理状态
                if [ $run -eq 1 ]; then
                    sleep 2  # 等 TIME-WAIT 自然回收一部分
                fi
                sleep 1
            done
            echo ""

            stop_server "$RESULT_DIR/.pid_${mode}" "$mode"
            sleep 2  # 等端口释放
        done
    } | tee "$out"

    log "bench.sh 并发完成 → $out"
}

# ============================================
#  D. pidstat CPU 监控（伴随长跑）
# ============================================
run_pidstat() {
    log "====== D. pidstat CPU 监控 ======"
    local out="$RESULT_DIR/D_pidstat.txt"

    {
        echo "=== pidstat CPU 监控 ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        for mode in lt et; do
            case $mode in
                lt) port=$PORT_LT; server="echo-epoll-lt-server"; sname="echo-epoll-lt";;
                et) port=$PORT_ET; server="echo-epoll-server"; sname="echo-epoll";;
            esac

            start_server "$mode" "$port" "$RESULT_DIR/.pid_${mode}"

            echo "--- ${server} pidstat ---"
            echo "采集间隔 1 秒，在 echo-bench 10000 req 期间采集"
            echo ""

            # 先启动 pidstat 监控
            local server_pid=$(cat "$RESULT_DIR/.pid_${mode}")
            pidstat -u -p "$server_pid" 1 > "$RESULT_DIR/pidstat_${mode}_raw.txt" 2>&1 &
            local pidstat_pid=$!

            # 等一下让 pidstat 初始化
            sleep 1

            # 启动压测（10000 req = 100 × 100）
            ./bin/echo-bench "$IP" "$port" 100 100 > "$RESULT_DIR/bench_${mode}_for_pidstat.txt" 2>&1

            # 等 pidstat 多采几秒，然后把压测期间的数据摘出来
            sleep 3
            kill $pidstat_pid 2>/dev/null || true
            wait $pidstat_pid 2>/dev/null || true

            echo ""
            echo "--- pidstat 原始输出 ---"
            cat "$RESULT_DIR/pidstat_${mode}_raw.txt"
            echo ""

            stop_server "$RESULT_DIR/.pid_${mode}" "$mode"
        done
    } | tee "$out"

    log "pidstat 完成 → $out"
}

# ============================================
#  E. strace epoll_wait 分析（伴随长跑，串行）
# ============================================
run_strace_epoll() {
    log "====== E. strace epoll_wait（串行 10000 req） ======"
    local out="$RESULT_DIR/E_strace_epoll.txt"

    {
        echo "=== strace -c -e epoll_wait（echo-bench 串行 10000 req） ==="
        echo "时间: $(date)"
        echo ""

        for mode in lt et; do
            case $mode in
                lt) port=$PORT_LT; server="echo-epoll-lt-server"; sname="echo-epoll-lt";;
                et) port=$PORT_ET; server="echo-epoll-server"; sname="echo-epoll";;
            esac

            start_server "$mode" "$port" "$RESULT_DIR/.pid_${mode}"

            echo "--- ${server} strace -c -e epoll_wait ---"

            local server_pid=$(cat "$RESULT_DIR/.pid_${mode}")
            strace -c -e epoll_wait -p "$server_pid" -o "$RESULT_DIR/strace_epoll_${mode}.txt" &
            local strace_pid=$!
            sleep 0.5

            ./bin/echo-bench "$IP" "$port" 100 100 > /dev/null 2>&1

            sleep 0.5
            kill -INT $strace_pid 2>/dev/null || true
            wait $strace_pid 2>/dev/null || true

            echo "=== strace 结果 ==="
            cat "$RESULT_DIR/strace_epoll_${mode}.txt"
            echo ""

            stop_server "$RESULT_DIR/.pid_${mode}" "$mode"
        done
    } | tee "$out"

    log "strace epoll_wait 完成 → $out"
}

# ============================================
#  F. strace 完整 syscall（伴随长跑，串行）
# ============================================
run_strace_full() {
    log "====== F. strace 完整 syscall 统计（串行 10000 req） ======"
    local out="$RESULT_DIR/F_strace_full.txt"

    {
        echo "=== strace -c 完整 syscall（echo-bench 串行 10000 req） ==="
        echo "时间: $(date)"
        echo ""

        for mode in lt et; do
            case $mode in
                lt) port=$PORT_LT; server="echo-epoll-lt-server"; sname="echo-epoll-lt";;
                et) port=$PORT_ET; server="echo-epoll-server"; sname="echo-epoll";;
            esac

            start_server "$mode" "$port" "$RESULT_DIR/.pid_${mode}"

            echo "--- ${server} strace -c (全 syscall) ---"

            local server_pid=$(cat "$RESULT_DIR/.pid_${mode}")
            strace -c -p "$server_pid" -o "$RESULT_DIR/strace_full_${mode}.txt" &
            local strace_pid=$!
            sleep 0.5

            ./bin/echo-bench "$IP" "$port" 100 100 > /dev/null 2>&1

            sleep 0.5
            kill -INT $strace_pid 2>/dev/null || true
            wait $strace_pid 2>/dev/null || true

            echo "=== strace 结果 ==="
            cat "$RESULT_DIR/strace_full_${mode}.txt"
            echo ""

            stop_server "$RESULT_DIR/.pid_${mode}" "$mode"
        done
    } | tee "$out"

    log "strace 完整 syscall 完成 → $out"
}

# ============================================
#  G. strace epoll_wait（bench.sh 并行）
# ============================================
run_strace_bench_sh() {
    log "====== G. strace epoll_wait（bench.sh 并行） ======"
    local out="$RESULT_DIR/G_strace_bench_sh.txt"

    {
        echo "=== strace -c -e epoll_wait（bench.sh 100 并发） ==="
        echo "时间: $(date)"
        echo ""

        for mode in lt et; do
            case $mode in
                lt) port=$PORT_LT; server="echo-epoll-lt-server"; sname="echo-epoll-lt";;
                et) port=$PORT_ET; server="echo-epoll-server"; sname="echo-epoll";;
            esac

            start_server "$mode" "$port" "$RESULT_DIR/.pid_${mode}"

            echo "--- ${server} strace -c -e epoll_wait（bench.sh 累计 330 并发） ---"

            local server_pid=$(cat "$RESULT_DIR/.pid_${mode}")
            strace -c -e epoll_wait -p "$server_pid" -o "$RESULT_DIR/strace_bench_sh_${mode}.txt" &
            local strace_pid=$!
            sleep 0.5

            # bench.sh 100 并发 × 3 次 = 330 总并发（匹配原实验设计）
            for i in 1 2 3; do
                bash bench.sh "$IP" "$port" 100 > /dev/null 2>&1
                sleep 1
            done

            sleep 0.5
            kill -INT $strace_pid 2>/dev/null || true
            wait $strace_pid 2>/dev/null || true

            echo "=== strace 结果 ==="
            cat "$RESULT_DIR/strace_bench_sh_${mode}.txt"
            echo ""

            stop_server "$RESULT_DIR/.pid_${mode}" "$mode"
            sleep 1
        done
    } | tee "$out"

    log "strace bench.sh 并行完成 → $out"
}

# ============================================
#  H. 并发 sweep（10→60→100→200）
# ============================================
run_concurrency_sweep() {
    log "====== H. 并发 sweep (bench.sh 10/20/30/40/50/60/100/200) ======"
    local out="$RESULT_DIR/H_concurrency_sweep.txt"

    {
        echo "=== bench.sh 并发 sweep ==="
        echo "时间: $(date)"
        echo "CPU: $(nproc) 核"
        echo ""

        for mode in lt et mp; do
            case $mode in
                lt) port=$PORT_LT; server="echo-epoll-lt-server";;
                et) port=$PORT_ET; server="echo-epoll-server";;
                mp) port=$PORT_MP; server="echo-mp-server";;
            esac

            start_server "$mode" "$port" "$RESULT_DIR/.pid_${mode}"

            echo "=== ${server} ==="
            for conc in 10 20 30 40 50 60 100 200; do
                echo "--- 并发=$conc ---"
                for run in 1 2 3; do
                    local start_ns=$(date +%s%N)
                    bash bench.sh "$IP" "$port" "$conc" > /dev/null 2>&1
                    local end_ns=$(date +%s%N)
                    local elapsed=$(( (end_ns - start_ns) / 1000000 ))
                    local qps=0
                    [ $elapsed -gt 0 ] && qps=$(( conc * 1000 / elapsed ))
                    echo "  Run $run: ${elapsed}ms, QPS≈$qps"
                    sleep 0.5
                done
            done
            echo ""

            stop_server "$RESULT_DIR/.pid_${mode}" "$mode"
        done
    } | tee "$out"

    log "并发 sweep 完成 → $out"
}

# ============================================
#  主流程
# ============================================

main() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  Day 2 Echo 实验 — 全量重跑                   ║"
    echo "║  机器: $(nproc) 核                             ║"
    echo "║  结果目录: $RESULT_DIR                        ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    collect_system_info
    compile_all
    echo ""

    local mode="${1:-all}"

    case "$mode" in
        --short)
            run_short_bench
            ;;
        --long)
            run_long_bench
            run_pidstat
            run_strace_epoll
            run_strace_full
            ;;
        --bench-sh)
            run_bench_sh
            ;;
        --sweep)
            run_concurrency_sweep
            ;;
        --strace)
            run_strace_epoll
            run_strace_full
            run_strace_bench_sh
            ;;
        --clean)
            log "清理..."
            make clean > /dev/null 2>&1 || true
            log "清理完成"
            exit 0
            ;;
        all)
            run_short_bench
            echo ""
            run_long_bench
            echo ""
            run_pidstat
            echo ""
            run_strace_epoll
            echo ""
            run_strace_full
            echo ""
            run_bench_sh
            echo ""
            run_strace_bench_sh
            echo ""
            run_concurrency_sweep
            ;;
        *)
            echo "用法: $0 [--short|--long|--bench-sh|--sweep|--strace|--clean]"
            echo "  无参数 = 全部实验"
            exit 1
            ;;
    esac

    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  全部实验完成！结果保存在:                     ║"
    echo "║  $RESULT_DIR                                 ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    # 汇总
    log "结果文件列表:"
    ls -la "$RESULT_DIR/"
}

main "$@"
