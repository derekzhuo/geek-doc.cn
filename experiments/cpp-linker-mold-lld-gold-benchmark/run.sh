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
bash gen_tus.sh "$NTU" src >/dev/null
expected_objects=$((NTU + 2))
t0=$(now_ms)
make objects NTU="$NTU" >/dev/null
t1=$(now_ms)
actual_objects=$(find build/obj -maxdepth 1 -type f -name '*.o' | wc -l)
if [ "$actual_objects" -ne "$expected_objects" ]; then
    log "FATAL: 实际对象数 $actual_objects，预期 $expected_objects"
    exit 1
fi
log "object_files=$actual_objects expected=$expected_objects assertion=PASS"
log "compile_all_ms=$((t1 - t0))  # 清理旧源码与产物后生成 $NTU TU + main + sumparts，再全部编译为 .o"
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
backup=$(mktemp)
cp src/tu0000.cpp "$backup"
trap 'cp "$backup" src/tu0000.cpp 2>/dev/null || true; rm -f "$backup"' EXIT
declare -A incremental_outputs
for ld in "${LINKERS[@]}"; do
    samples_link=()
    samples_compile=()
    for k in $(seq 1 "$INC_TRIALS"); do
        sed "s/acc = x + 0\.0;/acc = x + ${k}.25;/" "$backup" > src/tu0000.cpp
        a=$(now_ms)
        g++ -O2 -std=c++17 -Wall -I. -c src/tu0000.cpp -o build/obj/tu0000.o
        b=$(now_ms)
        make "build/bin/bench-$ld" NTU="$NTU" >/dev/null
        c=$(now_ms)
        samples_compile+=("$((b - a))")
        samples_link+=("$((c - b))")
        incremental_outputs["$ld,$k"]=$("build/bin/bench-$ld")
        log "incremental_run linker=$ld round=$k run=\"${incremental_outputs["$ld,$k"]}\""
    done
    med_link=$(median_ms "${samples_link[@]}")
    med_compile=$(median_ms "${samples_compile[@]}")
    log "incremental $ld relink_samples_ms=\"${samples_link[*]}\" relink_median_ms=$med_link recompile_samples_ms=\"${samples_compile[*]}\" recompile_median_ms=$med_compile"
done
for k in $(seq 1 "$INC_TRIALS"); do
    groups=$(for ld in "${LINKERS[@]}"; do printf '%s\n' "${incremental_outputs["$ld,$k"]}"; done | sort -u | wc -l)
    if [ "$groups" -ne 1 ]; then
        log "FATAL: 增量第 $k 轮四个二进制运行结果不一致"
        exit 1
    fi
    log "incremental_round=$k checksum_groups=$groups assertion=PASS"
done
cp "$backup" src/tu0000.cpp
rm -f "$backup"
trap - EXIT
log ""
log "done"
