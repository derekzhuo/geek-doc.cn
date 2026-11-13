#ifndef LINK_BENCH_WORK_HPP
#define LINK_BENCH_WORK_HPP

#include <cstdint>

// 每个 TU 都实例化一份的模板：制造跨 TU 的模板符号与重定位项，
// 让链接阶段有真实的符号解析与 GOT/PLT 处理工作，而不是只链接空 main。
template <int Seed>
inline std::int64_t mix_hash(std::int64_t x) {
    std::int64_t h = x + Seed * 0x9E3779B97F4A7C15LL;
    for (int i = 0; i < 8; ++i) {
        h ^= h >> 29;
        h *= 0xBF58476D1CE4E5B9LL;
        h ^= h >> 32;
    }
    return h;
}

double decay_step(double x);

#endif
