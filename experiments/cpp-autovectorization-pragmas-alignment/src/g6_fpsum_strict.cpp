#include "loops.hpp"

// G6：浮点归约严格模式。IEEE 浮点加法不满足结合律，
// 向量化必然改变求和顺序、改变舍入结果；没有显式授权时，
// 编译器宁可保留标量累加链。
double g6_fpsum_strict(const double* a, std::size_t n) {
    double s = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        s += a[i];
    }
    return s;
}
