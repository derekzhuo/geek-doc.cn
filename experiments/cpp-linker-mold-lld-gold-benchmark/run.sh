#!/usr/bin/env bash
# 四链接器全量/增量链接对照基准。
# 全量：同一批 .o，每个链接器干净重链 FULL_TRIALS 次，取中位数。
# 增量：每次只改一个 TU 的常量、重编该 TU、再链接，测重链耗时中位数。
# 结果写入 results.txt 并同时打印到终端。Linux GNU 环境，计时用 date +%s%N。
set -euo pipefail
cd "$(dirname "$0")"

NTU="${NTU:-300}"
FULL_TRIALS="${FULL_TRIALS:-7}"
INC_TRIALS="${INC_TRIALS:-5}"
LINKERS=(bfd gold lld mold)
RESULT=results.txt

now_ms() { date +%s%3N; }
median_ms() { printf '%s\n' "$@" | sort -n | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]}'; }

: > "$RESULT"
log() { echo "$@" | tee -a "$RESULT"; }

log "\$ NTU=$NTU bash run.sh"
log "# 链接器对照基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# host: $(uname -srm) | $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
log "# nproc: $(nproc) | g++: $(g++ --version | head -1)"
for ld in "${LINKERS[@]}"; do
    if [ "$ld" = mold ]; then
        log "# mold: $(mold --version 2>&1 | head -1)"
    else
        log "# ld.$ld: $(ld.$ld --version 2>&1 | head -1)"
    fi
done
log "# NTU=$NTU FULL_TRIALS=$FULL_TRIALS INC_TRIALS=$INC_TRIALS CXXFLAGS=-O2 -std=c++17 -Wall"
log ""

make clean >/dev/null
t0=$(now_ms)
make objects NTU="$NTU" >/dev/null
t1=$(now_ms)
log "compile_all_ms=$((t1 - t0))  # 生成 $NTU TU + main + sumparts 并全部编译为 .o"
log ""

log "== 全量链接（每次先删二进制，链接全部 $((NTU + 2)) 个 .o）=="
declare -A checksums
for ld in "${LINKERS[@]}"; do
    bin="build/bin/bench-$ld"
    samples=()
    for k in $(seq 1 "$FULL_TRIALS"); do
        rm -f "$bin"
        a=$(now_ms)
        make "$bin" NTU="$NTU" >/dev/null
        b=$(now_ms)
        samples+=("$((b - a))")
    done
    med=$(median_ms "${samples[@]}")
    size=$(stat -c%s "$bin")
    out=$("$bin")
    checksums[$ld]="$out"
    log "full $ld samples_ms=\"${samples[*]}\" median_ms=$med size_bytes=$size run=\"$out\""
done
log ""

uniq_checksums=$(for ld in "${LINKERS[@]}"; do echo "${checksums[$ld]}"; done | sort -u | wc -l)
if [ "$uniq_checksums" -ne 1 ]; then
    log "FATAL: 四个二进制运行结果不一致"
    exit 1
fi
log "checksum 一致：$uniq_checksums 组输出完全相同"
log ""

log "== 增量链接（每轮只改 tu0000.cpp 一个常量，重编该 TU 后重链）=="
cp src/tu0000.cpp /tmp/tu0000.cpp.bak
trap 'mv /tmp/tu0000.cpp.bak src/tu0000.cpp 2>/dev/null || true' EXIT
for ld in "${LINKERS[@]}"; do
    samples_link=()
    samples_compile=()
    for k in $(seq 1 "$INC_TRIALS"); do
        sed "s/acc = x + 0\.0;/acc = x + ${k}.25;/" /tmp/tu0000.cpp.bak > src/tu0000.cpp
        a=$(now_ms)
        g++ -O2 -std=c++17 -Wall -I. -c src/tu0000.cpp -o build/obj/tu0000.o
        b=$(now_ms)
        make "build/bin/bench-$ld" NTU="$NTU" >/dev/null
        c=$(now_ms)
        samples_compile+=("$((b - a))")
        samples_link+=("$((c - b))")
    done
    mv /tmp/tu0000.cpp.bak src/tu0000.cpp
    g++ -O2 -std=c++17 -Wall -I. -c src/tu0000.cpp -o build/obj/tu0000.o
    cp src/tu0000.cpp /tmp/tu0000.cpp.bak
    med_link=$(median_ms "${samples_link[@]}")
    med_compile=$(median_ms "${samples_compile[@]}")
    log "incremental $ld relink_samples_ms=\"${samples_link[*]}\" relink_median_ms=$med_link recompile_median_ms=$med_compile"
done
log ""
log "done"
