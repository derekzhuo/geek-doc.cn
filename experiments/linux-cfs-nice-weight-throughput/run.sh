#!/usr/bin/env bash
# CFS nice 权重扫档编排：
#   两组燃烧进程（每组 2 个，共 4 个，对 2 vCPU 形成 2 倍超额订阅），
#   nice 组合 base(0/0)、n10(0/10)、n20(0/20)、neg10(-10/0) 各连跑 5 次，
#   用 getrusage 自报 utime 与 /proc/PID/stat 外部采样双口径算组间 CPU 时间比，
#   再对 n10 组合采一次 perf stat 调度事件。负 nice 需要 sudo。
set -euo pipefail
cd "$(dirname "$0")"

REPS="${REPS:-5}"
PROCS_PER_GROUP="${PROCS_PER_GROUP:-2}"
WINDOW_SEC="${WINDOW_SEC:-8}"           # 外部采样窗口
BURN_SEC=$((WINDOW_SEC + 1))            # 燃烧进程多跑 1 秒，给采样留竞态余量
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# --one 递归调用写独立文件，避免截断主跑的 results.txt
RESULT_FILE="results.txt"
if [ "${1:-}" = "--one" ]; then
    RESULT_FILE="results-single.txt"
fi
: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

make >/dev/null

log "# CFS nice weight 基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# host: $(hostname) | kernel: $(uname -r)"
log "# distro: $(lsb_release -ds 2>/dev/null || echo unknown)"
log "# compiler: $(gcc --version | head -1)"
log "# cpu: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
lscpu | grep -E '^CPU\(s\)|Thread|Core|Socket' | sed 's/^/# lscpu: /' | tee -a "$RESULT_FILE"
log "# CLK_TCK=$(getconf CLK_TCK) | 每组 ${PROCS_PER_GROUP} 进程 | 窗口 ${WINDOW_SEC}s | 重复 ${REPS} 次"

# run_once <combo> <niceA> <niceB> <rep>
run_once() {
    local combo="$1" nice_a="$2" nice_b="$3" rep="$4"
    local out="$TMP/${combo}-${rep}.out"
    local -a pids_a=() pids_b=()
    declare -A start_jf=()
    local pid i

    spawn_group() {
        local nice_val="$1" group="$2" count="$3"
        local -n pids_ref="$4"
        for ((i = 0; i < count; ++i)); do
            # root 下直接 nice（sudo 会 fork，$! 跟踪到的是休眠父进程，
            # 让 /proc 采样失效）；普通用户才用 sudo 提权负 nice
            if [ "$nice_val" -lt 0 ] && [ "$(id -u)" -ne 0 ]; then
                sudo nice -n "$nice_val" ./bin/nice_bench "$BURN_SEC" "$group" >>"$out" 2>&1 &
            else
                nice -n "$nice_val" ./bin/nice_bench "$BURN_SEC" "$group" >>"$out" 2>&1 &
            fi
            pid=$!
            pids_ref+=("$pid")
            start_jf[$pid]=$(awk '{print $14}' "/proc/$pid/stat")
        done
    }
    : >"$out"
    spawn_group "$nice_a" A "$PROCS_PER_GROUP" pids_a
    spawn_group "$nice_b" B "$PROCS_PER_GROUP" pids_b

    sleep "$WINDOW_SEC"
    # 外部口径：窗口结束瞬间读 /proc/PID/stat 第 14 列 utime（jiffies）
    local end_a=0 end_b=0 start_a=0 start_b=0
    for pid in "${pids_a[@]}"; do
        end_a=$((end_a + $(awk '{print $14}' "/proc/$pid/stat")))
        start_a=$((start_a + ${start_jf[$pid]}))
    done
    for pid in "${pids_b[@]}"; do
        end_b=$((end_b + $(awk '{print $14}' "/proc/$pid/stat")))
        start_b=$((start_b + ${start_jf[$pid]}))
    done
    wait

    local ut_a ut_b delta_a delta_b ratio jratio
    ut_a=$(grep '^BURN' "$out" | grep 'group=A' | sed 's/.*utime_ms=//; s/ .*//' | awk '{s+=$1} END{printf "%.2f", s}')
    ut_b=$(grep '^BURN' "$out" | grep 'group=B' | sed 's/.*utime_ms=//; s/ .*//' | awk '{s+=$1} END{printf "%.2f", s}')
    delta_a=$((end_a - start_a))
    delta_b=$((end_b - start_b))
    ratio=$(awk -v a="$ut_a" -v b="$ut_b" 'BEGIN{printf "%.3f", (b>0?a/b:0)}')
    jratio=$(awk -v a="$delta_a" -v b="$delta_b" 'BEGIN{printf "%.3f", (b>0?a/b:0)}')
    log "RESULT combo=$combo rep=$rep niceA=$nice_a niceB=$nice_b procs=$PROCS_PER_GROUP utimeA_ms=$ut_a utimeB_ms=$ut_b ratio=$ratio jiffyA=$delta_a jiffyB=$delta_b jratio=$jratio"
}

COMBOS=("base:0:0" "n10:0:10" "n20:0:20" "neg10:-10:0")
ONE_SHOT=0
if [ "${1:-}" = "--one" ]; then
    shift
    COMBOS=("$1")
    REPS=1
    ONE_SHOT=1
fi

log ""
log "===== 四组 nice 组合各 ${REPS} 次重复（4 进程超额订阅 2 vCPU） ====="
for entry in "${COMBOS[@]}"; do
    combo="${entry%%:*}"
    rest="${entry#*:}"
    nice_a="${rest%%:*}"
    nice_b="${rest##*:}"
    for rep in $(seq 1 "$REPS"); do
        run_once "$combo" "$nice_a" "$nice_b" "$rep"
    done
done

if [ "$ONE_SHOT" -eq 0 ]; then
    log ""
    log "===== 各组合五次重复的 CPU 时间比中位（getrusage 与 /proc 双口径） ====="
    grep '^RESULT' "$RESULT_FILE" | awk '
    function median_of(arr, n,   i,j,t) {
        for (i=1;i<=n;++i) for (j=i+1;j<=n;++j)
            if (arr[j]<arr[i]) { t=arr[i]; arr[i]=arr[j]; arr[j]=t }
        return arr[int((n+1)/2)]
    }
    {
        for (i=1;i<=NF;++i) {
            split($i,k,"=")
            if (k[1]=="combo") c=k[2]
            if (k[1]=="ratio") r[c]=(c in r?r[c]" "k[2]:k[2])
            if (k[1]=="jratio") jr[c]=(c in jr?jr[c]" "k[2]:k[2])
        }
    }
    END {
        for (c in r) {
            n=split(r[c],ra," "); split(jr[c],jb," ")
            printf "MEDIAN combo=%-6s ratio=%8.3f jratio=%8.3f n=%d\n", c, median_of(ra,n), median_of(jb,n), n
        }
    }' | sort | tee -a "$RESULT_FILE"

    log ""
    log "===== perf stat 佐证（n10 组合，sudo） ====="
    sudo perf stat -e context-switches,cpu-migrations,task-clock \
        bash run.sh --one "n10:0:10" 2>&1 | tee -a "$RESULT_FILE"
fi

log "done"
