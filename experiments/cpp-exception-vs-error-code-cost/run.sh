#!/usr/bin/env bash
# 异常/错误码/Expected 基准编排：
#   干净重建后运行 7 次（二进制内已含预热），按 mechanism×path 六格取耗时中位，
#   再采集异常处理相关符号与段大小证据。
set -euo pipefail
cd "$(dirname "$0")"

CXX_USED="${CXX:-clang++}"
RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

log "# 异常 vs 错误码 vs Expected 基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $($CXX_USED --version | head -1)"
log "# flags: -O2 -std=c++17 -Wall，成功路径 5000 万次/格，错误路径 200 万次/格，运行 ${RUNS} 次"
log ""

make clean >/dev/null
make CXX="$CXX_USED" >/dev/null

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for i in $(seq 1 "$RUNS"); do
    ./bin/bench >> "$TMP/raw.txt"
done

for mech in exception errcode expected; do
    for path in ok fail; do
        vals="$(grep "mechanism=${mech} " "$TMP/raw.txt" | grep " path=${path} " | sed 's/.*elapsed_ms= *\([0-9.]*\).*/\1/')"
        cs="$(grep "mechanism=${mech} " "$TMP/raw.txt" | grep " path=${path} " | head -1 | sed 's/.*checksum=//')"
        log "$(printf '%-9s %-5s median_ms=%s checksum=%s' "$mech" "$path" "$(median $vals)" "$cs")"
    done
done

log ""
log "== 异常机制证据 =="
{
echo "## 异常处理人格符号（仅异常实现需要）"
nm bin/bench | grep -i personality || echo "(无 personality 符号)"
echo ""
echo "## __gcc_except_tab 段（异常处理表，正常代码不进热路径）"
otool -l bin/bench | grep -A3 "__gcc_except_tab" | head -8 || echo "(无该段)"
echo ""
echo "## 成功路径热循环反汇编（run_except_ok，正常路径无 call/无异常指令）"
otool -tvV bin/bench | awk '/__Z13run_except_okl:/{f=1} f{print} f&&/retq/{exit}' | grep -E "callq|ud2|retq|jne|jmp" | head -8
} | tee -a "$RESULT_FILE"
log "done"
