#!/usr/bin/env bash
# 生成 N 个结构同构、符号不同的翻译单元 worker0..workerN-1.cpp。
# 多 TU 是 LTO 发挥作用的前提：单 TU 编译期即可内联，无法体现链接期优化差异。
set -euo pipefail
N="${1:-8}"
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
for i in $(seq 0 $((N - 1))); do
cat > "worker${i}.cpp" <<EOF
#include "work.hpp"

namespace {

constexpr int INNER_LOOPS = 2000;

struct Worker${i} final : Worker {
    std::int64_t compute(std::int64_t seed) const override {
        // 各次调用互不携带依赖（输入只由 r/seed 决定），
        // 内联后编译器可以展开、流水线化；无 LTO 时每次都是真实跨 TU call。
        std::int64_t acc = seed + ${i} * 7919LL;
        for (int r = 0; r < INNER_LOOPS; ++r) {
            acc += mix_step(seed + static_cast<std::int64_t>(r), r + ${i});
        }
        return acc;
    }
};

}  // namespace

extern "C" Worker* makeWorker${i}() {
    return new Worker${i}();
}
EOF
done
echo "generated ${N} worker translation units"
