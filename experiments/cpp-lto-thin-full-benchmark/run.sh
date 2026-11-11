#!/usr/bin/env bash
# 三档 LTO 全量基准：
#  - 每档干净重建 BUILD_TRIALS 次，构建耗时取中位数；
#  - 二进制体积取最后一次构建产物；
#  - 运行先做 1 次预热（dyld/缺页冷启动不计入），再计时 RUNS 次取中位数。
# 结果同时打印到终端并写入 results.txt（覆盖）。macOS 的 date 无 %N，计时走 perl Time::HiRes。
set -euo pipefail
cd "$(dirname "$0")"

CXX_USED="${CXX:-clang++}"
RUNS="${RUNS:-7}"
BUILD_TRIALS="${BUILD_TRIALS:-3}"
RESULT_FILE="results.txt"

now() { perl -MTime::HiRes=time -e 'printf "%.3f", time'; }
median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

log "# LTO 三档基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $($CXX_USED --version | head -1)"
log "# flags: -O2 -std=c++17 -Wall，workers=8，outer=2000，运行 ${RUNS} 次（另含 1 次预热），构建测 ${BUILD_TRIALS} 次"
log ""

for cfg in none full thin; do
    target="bin/lto-${cfg}"
    build_samples=()
    for trial in $(seq 1 "$BUILD_TRIALS"); do
        make clean >/dev/null
        t0="$(now)"
        make "$target" CXX="$CXX_USED" >/dev/null
        t1="$(now)"
        build_samples+=("$(perl -e "printf \"%.0f\", ($t1-$t0)*1000")")
    done
    build_med="$(median "${build_samples[@]}")"
    size_bytes="$(stat -f%z "$target")"

    log "== ${cfg} =="
    log "build_samples_ms=${build_samples[*]} build_median_ms=${build_med} size_bytes=${size_bytes}"

    "$target" >/dev/null  # 预热，不记录
    run_samples=()
    for i in $(seq 1 "$RUNS"); do
        line="$("$target")"
        echo "$line" >> "$RESULT_FILE"
        ms="${line#elapsed_ms=}"
        run_samples+=("${ms%% *}")
    done
    run_med="$(median "${run_samples[@]}")"
    log "runtime_median_ms=${run_med}"
    log ""
done

make clean >/dev/null
log "done"
