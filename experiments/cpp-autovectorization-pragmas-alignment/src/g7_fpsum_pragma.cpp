#include "loops.hpp"

// G7：与 G6 完全相同的浮点归约，加一句 pragma 显式授权重排。
// 这是程序员知情后的取舍：拿可接受的浮点误差换向量宽度，
// 等价的全局开关是 -ffast-math，但 pragma 只作用于这一个循环。
double g7_fpsum_pragma(const double* a, std::size_t n) {
    double s = 0.0;
#pragma clang loop vectorize(enable)
    for (std::size_t i = 0; i < n; ++i) {
        s += a[i];
    }
    return s;
}
