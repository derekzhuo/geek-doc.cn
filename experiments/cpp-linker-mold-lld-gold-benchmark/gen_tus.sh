#!/usr/bin/env bash
# 生成 NTU 个翻译单元 + 汇总声明头 + main.cpp。
# 用法: gen_tus.sh <NTU> [输出目录]
set -euo pipefail

NTU="${1:?usage: gen_tus.sh <NTU> [outdir]}"
OUTDIR="${2:-src}"
mkdir -p "$OUTDIR"

DECLS="$OUTDIR/tu_decls.h"
: > "$DECLS"
echo "#pragma once" >> "$DECLS"
echo "#include <cstdint>" >> "$DECLS"

for i in $(seq 0 $((NTU - 1))); do
    id=$(printf "%04d" "$i")
    cat > "$OUTDIR/tu${id}.cpp" <<EOF
#include "work.hpp"

double tu_compute_${id}(double x) {
    double acc = x + ${i}.0;
    for (int k = 0; k < 64; ++k) {
        acc = decay_step(acc) + static_cast<double>(mix_hash<${i}>(k) & 0xffff) * 1e-6;
    }
    return acc;
}

std::int64_t tu_hash_${id}(std::int64_t x) {
    return mix_hash<${i}>(x);
}
EOF
    echo "double tu_compute_${id}(double x);" >> "$DECLS"
    echo "std::int64_t tu_hash_${id}(std::int64_t x);" >> "$DECLS"
done

cat > "$OUTDIR/main.cpp" <<EOF
#include <cstdio>
#include "tu_decls.h"

int main() {
    double sum = 0.0;
    std::int64_t h = 0;
    for (int i = 0; i < ${NTU}; ++i) {
        switch (i) {
$(for i in $(seq 0 $((NTU - 1))); do id=$(printf "%04d" "$i"); printf "            case %s: sum += tu_compute_%s(1.5 + i); h ^= tu_hash_%s(h + i); break;\n" "$i" "$id" "$id"; done)
        }
    }
    std::printf("checksum=%.6f hash=%lld\\n", sum, static_cast<long long>(h));
    return 0;
}
EOF

echo "generated $NTU TUs in $OUTDIR"
