#include "loops.hpp"

// G8：对齐干预。两个函数的循环体一模一样，且都显式授权浮点重排，
// 唯一变量是入口对齐信息。aligned 版本由调用方传入 64 字节对齐缓冲，
// 再用内建函数把对齐信息告诉编译器，向量 load 可走对齐指令；
// misaligned 版本收到基址偏移 8 字节的错位指针，只能走非对齐 load。
double g8_aligned_sum(const double* a, std::size_t n) {
    const double* p =
        static_cast<const double*>(__builtin_assume_aligned(a, 64));
    double s = 0.0;
#pragma clang loop vectorize(enable)
    for (std::size_t i = 0; i < n; ++i) {
        s += p[i];
    }
    return s;
}

double g8_misaligned_sum(const double* a, std::size_t n) {
    double s = 0.0;
#pragma clang loop vectorize(enable)
    for (std::size_t i = 0; i < n; ++i) {
        s += a[i];
    }
    return s;
}
