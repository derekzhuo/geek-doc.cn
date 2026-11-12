#include "loops.hpp"

// G3：递推。第 i 次迭代读 a[i-1]，而它是上一轮刚写出的值，
// 形成反向循环携带依赖（backward loop-carried dependence）。
// SIMD 一条指令要求 lanes 之间互不等待，这种串行链无法加宽。
void g3_recurrence(double* a, std::size_t n) {
    for (std::size_t i = 1; i < n; ++i) {
        a[i] = a[i - 1] * 1.0001 + 1.0;
    }
}
