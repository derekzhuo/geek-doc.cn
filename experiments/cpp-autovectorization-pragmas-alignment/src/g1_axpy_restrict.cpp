#include "loops.hpp"

// G1：最教科书的可向量化循环。restrict 承诺 a 与 b 不重叠，
// 每次迭代只写自己的 a[i]，迭代之间没有任何依赖。
void g1_axpy_restrict(double* __restrict a,
                      const double* __restrict b,
                      double s, std::size_t n) {
    for (std::size_t i = 0; i < n; ++i) {
        a[i] += s * b[i];
    }
}
