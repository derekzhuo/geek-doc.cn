#include "loops.hpp"

// G9：展开干预。两个整数归约都能向量化，变量是展开倍数。
// pragma 要求编译器把循环体展开 8 份，拉开迭代间距离，
// 给乱序执行更多独立指令；注意它只控制展开，不解除 G6 那类浮点禁令。
long g9_isum_plain(const long* a, std::size_t n) {
    long s = 0;
    for (std::size_t i = 0; i < n; ++i) {
        s += a[i];
    }
    return s;
}

long g9_isum_unroll(const long* a, std::size_t n) {
    long s = 0;
#pragma clang loop unroll_count(8)
    for (std::size_t i = 0; i < n; ++i) {
        s += a[i];
    }
    return s;
}
