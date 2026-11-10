#!/usr/bin/env bash
# PGO 两阶段基准完整编排：
#   1) 构建 baseline 与插桩二进制；2) 用训练负载跑插桩版采剖面；
#   3) llvm-profdata merge 合并剖面并 show 留证；4) 剖面引导重建 pgo 版；
#   5) matched / uniform 两种评估负载各预热 1 次、计时 7 次取中位。
set -euo pipefail
cd "$(dirname "$0")"

CXX_USED="${CXX:-clang++}"
RUNS="${RUNS:-7}"
PROFDATA="$(xcrun -find llvm-profdata 2>/dev/null || command -v llvm-profdata)"
RESULT_FILE="results.txt"

now() { perl -MTime::HiRes=time -e 'printf "%.3f", time'; }
median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

log "# PGO 两阶段基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $($CXX_USED --version | head -1)"
log "# profdata: $PROFDATA"
log "# flags: -O2 -std=c++17 -Wall，迭代 3000 万次/轮，运行 ${RUNS} 次（另含 1 次预热）"
log ""

make clean >/dev/null
make bin/baseline bin/instrumented CXX="$CXX_USED" >/dev/null

log "== 阶段 1：插桩版采训练剖面（偏斜负载 90/5/4/1） =="
./bin/instrumented train | tee -a "$RESULT_FILE"
RAW_PROFILE="$(ls -t *.profraw | head -1)"
"$PROFDATA" merge -output=pgo.profdata "$RAW_PROFILE"
log "merge 输出：pgo.profdata（$(stat -f%z pgo.profdata) B）"
log ""
log "== 剖面摘要（llvm-profdata show --detailed-summary） =="
"$PROFDATA" show --detailed-summary pgo.profdata 2>&1 | tee -a "$RESULT_FILE"
log ""

log "== 阶段 2：剖面引导重建 =="
make bin/pgo CXX="$CXX_USED" >/dev/null
log "baseline 体积：$(stat -f%z bin/baseline) B"
log "pgo 体积：$(stat -f%z bin/pgo) B"
log ""

for mode in matched uniform; do
    log "== 评估负载：${mode} =="
    for bin in baseline pgo; do
        "./bin/${bin}" "$mode" >/dev/null  # 预热
        samples=()
        cs_first=""
        for i in $(seq 1 "$RUNS"); do
            line="$("./bin/${bin}" "$mode")"
            echo "$line" >> "$RESULT_FILE"
            ms="${line#*elapsed_ms=}"
            samples+=("${ms%% *}")
            [ -z "$cs_first" ] && cs_first="${line##*checksum=}"
        done
        log "${bin} runtime_median_ms=$(median "${samples[@]}") checksum=${cs_first}"
    done
    log ""
done

make clean >/dev/null
log "done"
