#!/usr/bin/env bash
# RVO/NRVO/移动语义基准编排：
#   默认构建跑 7 次，对大规模扩容两格取耗时中位；
#   再用 -fno-elide-constructors 构建反证复制消除的作用，对照 RVO/NRVO 计数。
set -euo pipefail
cd "$(dirname "$0")"

CXX_USED="${CXX:-clang++}"
RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

log "# RVO/NRVO/移动语义与 vector 扩容基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $($CXX_USED --version | head -1)"
log "# flags: -O2 -std=c++17 -Wall；反证构建叠加 -fno-elide-constructors"
log ""

make clean >/dev/null
make CXX="$CXX_USED" >/dev/null

log "===== 默认构建（复制消除开启）单次完整输出 ====="
./bin/bench | tee -a "$RESULT_FILE"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for i in $(seq 1 "$RUNS"); do
    ./bin/bench >> "$TMP/raw.txt"
done

log ""
log "===== 大规模扩容 7 次计时中位（N=200000） ====="
for tag in safe risky; do
    vals="$(grep "^grow  $tag " "$TMP/raw.txt" | grep "n=200000" | sed 's/.*elapsed_ms= *\([0-9.]*\).*/\1/')"
    copies="$(grep "^grow  $tag " "$TMP/raw.txt" | grep "n=200000" | head -1 | sed 's/.*copy_ctor=\([0-9]*\).*/\1/')"
    moves="$(grep "^grow  $tag " "$TMP/raw.txt" | grep "n=200000" | head -1 | sed 's/.*move_ctor=\([0-9]*\).*/\1/')"
    log "$(printf '%-6s n=200000 median_ms=%s copy_ctor=%s move_ctor=%s' "$tag" "$(median $vals)" "$copies" "$moves")"
done

log ""
log "===== 反证构建 -fno-elide-constructors 的 RVO/NRVO 计数 ====="
./bin/bench-no-elide | grep -E "^(rvo|nrvo)" | tee -a "$RESULT_FILE"
log "done"
