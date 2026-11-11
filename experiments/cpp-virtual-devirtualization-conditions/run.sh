#!/usr/bin/env bash
# 去虚化条件基准完整编排：
#   1) 构建 none / lto 两档；2) 构建插桩版跑训练、merge 剖面、构建 pgo 档；
#   3) 三档各运行 7 次（二进制内部已含 1 次预热），按形态取耗时中位；
#   4) collect-evidence.sh 按符号地址区间统计间接调用并摘录热循环。
set -euo pipefail
cd "$(dirname "$0")"

CXX_USED="${CXX:-clang++}"
RUNS="${RUNS:-7}"
PROFDATA="$(xcrun -find llvm-profdata 2>/dev/null || command -v llvm-profdata)"
RESULT_FILE="results.txt"
FORMS="direct heap_open heap_final visible_local cross_tu"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

log "# 虚函数去虚化条件基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $($CXX_USED --version | head -1)"
log "# flags: -O2 -std=c++17 -Wall，100M 次/形态，运行 ${RUNS} 次（二进制内另含预热）"
log ""

make clean >/dev/null
make bin/bench-none bin/bench-lto bin/bench-instrumented CXX="$CXX_USED" >/dev/null

log "== 训练插桩版并合并剖面 =="
./bin/bench-instrumented train | tee -a "$RESULT_FILE"
RAW_PROFILE="$(ls -t *.profraw | head -1)"
"$PROFDATA" merge -output=pgo.profdata "$RAW_PROFILE"
log "merge 输出：pgo.profdata（$(stat -f%z pgo.profdata) B）"
make bin/bench-pgo CXX="$CXX_USED" >/dev/null
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for bin in none lto pgo; do
    log "== 配置档：${bin} =="
    for i in $(seq 1 "$RUNS"); do
        "./bin/bench-${bin}" run >> "$TMP/${bin}.raw"
    done
    for form in $FORMS; do
        vals="$(grep "form=${form} " "$TMP/${bin}.raw" | sed 's/.*elapsed_ms= *\([0-9.]*\).*/\1/')"
        cs="$(grep "form=${form} " "$TMP/${bin}.raw" | head -1 | sed 's/.*checksum=//')"
        log "$(printf '%-13s median_ms=%s checksum=%s' "$form" "$(median $vals)" "$cs")"
    done
    log ""
done

log "== 反汇编证据 =="
bash collect-evidence.sh >> "$RESULT_FILE" 2>&1
log "done"
