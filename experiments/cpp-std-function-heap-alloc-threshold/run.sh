#!/usr/bin/env bash
# std::function SBO 阈值基准编排：
#   -O2 与 -O0 两个二进制各跑 7 次，按探针取构造/调用耗时中位；
#   另以 nm/otool 固定 operator new 重载证据与堆路径调用点。
set -euo pipefail
cd "$(dirname "$0")"

RUNS="${RUNS:-7}"
RESULT_FILE="results.txt"

median() { perl -e '@v=sort{$a<=>$b}@ARGV;print $v[int(@v/2)]' "$@"; }

: > "$RESULT_FILE"
log() { echo "$@" | tee -a "$RESULT_FILE"; }

make clean >/dev/null
make >/dev/null

log "# std::function SBO 阈值基准 ($(date '+%Y-%m-%d %H:%M:%S'))"
log "# compiler: $(clang++ --version | head -1)"
log "# flags: -std=c++17 -Wall -Wextra；O2/O0 各运行 ${RUNS} 次取中位"
log ""

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for opt in O2 O0; do
    for i in $(seq 1 "$RUNS"); do
        "./bin/bench-${opt}" > "$TMP/${opt}-${i}.txt"
    done
done

log "===== -O2 首次完整输出 ====="
cat "$TMP/O2-1.txt" | tee -a "$RESULT_FILE"
log ""

# 从单次输出里按 "# ---- tag ----" 分段抽耗时行
extract_ns() {
    local file="$1" kind="$2"
    awk -v kind="$kind" '
        /^# ----/ { tag=$0; sub(/^# ---- /,"",tag); sub(/ ----$/,"",tag) }
        kind=="ctor" && /ctor\/dtor/ {
            n=$0; sub(/^.*\(/,"",n); sub(/ ns.*$/,"",n); print tag "\t" n
        }
        kind=="call" && /^call / {
            n=$0; sub(/^.*\(/,"",n); sub(/ ns.*$/,"",n); print tag "\t" n
        }
    ' "$file"
}

for opt in O2 O0; do
    log "===== -${opt} 各探针 ${RUNS} 次耗时中位 (ns/次) ====="
    log "$(printf '%-28s %12s %12s' '探针' '构造/析构' '调用')"
    tags=$(awk -F'\t' '{print $1}' <(extract_ns "$TMP/${opt}-1.txt" ctor))
    while IFS= read -r tag; do
        ctor_vals=(); call_vals=()
        for i in $(seq 1 "$RUNS"); do
            c="$(extract_ns "$TMP/${opt}-${i}.txt" ctor | awk -F'\t' -v t="$tag" '$1==t{print $2}')"
            v="$(extract_ns "$TMP/${opt}-${i}.txt" call | awk -F'\t' -v t="$tag" '$1==t{print $2}')"
            ctor_vals+=("$c"); call_vals+=("$v")
        done
        log "$(printf '%-28s %12s %12s' "$tag" "$(median "${ctor_vals[@]}")" "$(median "${call_vals[@]}")")"
    done <<< "$tags"
    log ""
done

log "===== 分配计数汇总（-O2 首次输出，每个探针的单次构造） ====="
awk '/^# ----/{tag=$0} /construct:|move-construct:/{print tag"  "$0}' "$TMP/O2-1.txt" | tee -a "$RESULT_FILE"
log ""

log "===== 二进制证据：operator new 被本程序重载（T=本二进制定义） ====="
nm bin/bench-O2 | grep -E "(__Znwm|__Znam|align_val_t)" | head -8 | tee -a "$RESULT_FILE"
log ""
log "===== 反汇编证据：operator new 在 -O2 被内联，堆路径直接调用 malloc ====="
otool -tvV bin/bench-O2 | awk '/callq/{print $NF}' | grep -E "^_malloc$|aligned_alloc" | sort | uniq -c | tee -a "$RESULT_FILE" || true
log "done"
