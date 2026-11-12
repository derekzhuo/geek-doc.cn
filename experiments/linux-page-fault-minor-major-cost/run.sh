#!/usr/bin/env bash
# minor/major 缺页成本扫档编排：
#   五个配置各连跑 5 次进程（进程内再重复 5 轮），对 ns_per_fault 取五次进程中位；
#   再用 perf stat 对匿名冷缺页与文件 major 缺页两个代表配置采硬件/软件事件。
# 需要 sudo（drop_caches 与 perf 计数）。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-5}"
DATA="datafile.bin"
RESULT_FILE="results.txt"
: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

make clean >/dev/null
make >/dev/null

log "# minor/major page fault 基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# host: $(hostname) | kernel: $(uname -r)"
log "# distro: $(lsb_release -ds 2>/dev/null || echo unknown)"
log "# compiler: $(gcc --version | head -1)"
log "# cpu: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
lscpu | grep -E '^CPU\(s\)|Thread|Core|Socket|L1d|L2|L3|NUMA node' | sed 's/^/# lscpu: /' | tee -a "$RESULT_FILE"

if [ ! -f "$DATA" ]; then
    log "生成 200 MiB 数据文件（urandom，避免零页去重）"
    dd if=/dev/urandom of="$DATA" bs=1M count=200 status=none
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log ""
log "===== 五配置各 ${RUNS} 次进程运行 ====="
for i in $(seq 1 "$RUNS"); do
    log "--- 第 ${i} 次进程 ---"
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    for cfg in anon_cold anon_refault anon_prefault file_cold file_warm; do
        if [[ "$cfg" == file_* ]]; then
            sudo ./bin/pf_bench "$cfg" "$DATA"
        else
            ./bin/pf_bench "$cfg"
        fi | tee -a "$RESULT_FILE"
    done
done

log ""
log "===== 五次进程中位汇总（按 cfg，ns_per_fault 与 ns_per_page） ====="
grep -h '^RESULT' "$RESULT_FILE" | awk '
function median_of(arr, n,   i,j,t) {
    for (i=1;i<=n;++i) for (j=i+1;j<=n;++j)
        if (arr[j]<arr[i]) { t=arr[i]; arr[i]=arr[j]; arr[j]=t }
    return arr[int((n+1)/2)]
}
{
    split($2,a,"=")
    vf=$0; sub(/^.*ns_per_fault= */, "", vf); sub(/ .*$/, "", vf)
    vp=$0; sub(/^.*ns_per_page= */, "", vp); sub(/ .*$/, "", vp)
    key=a[2]
    nf[key]=(key in nf ? nf[key] " " vf : vf)
    np[key]=(key in np ? np[key] " " vp : vp)
}
END {
    for (k in nf) {
        split(nf[k],af," "); split(np[k],ap," ")
        printf "MEDIAN cfg=%-13s ns_per_fault=%10.2f ns_per_page=%9.2f\n", \
            k, median_of(af,length(af)), median_of(ap,length(ap))
    }
}' | sort | tee -a "$RESULT_FILE"

log ""
log "===== perf stat 佐证（代表配置，sudo） ====="
for cfg in anon_cold file_cold; do
    log "--- perf ${cfg} ---"
    if [[ "$cfg" == file_* ]]; then
        sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
        sudo perf stat -e page-faults,minor-faults,major-faults,cycles,instructions \
            ./bin/pf_bench "$cfg" "$DATA" 2>&1 | tee -a "$RESULT_FILE"
    else
        sudo perf stat -e page-faults,minor-faults,major-faults,cycles,instructions \
            ./bin/pf_bench "$cfg" 2>&1 | tee -a "$RESULT_FILE"
    fi
    log ""
done

log "done"
