#include "loops.hpp"

// G5：分散写（scatter）。写入位置 v[idx[i]] 由运行时下标决定，
// 编译器无法证明两个 lane 不会写同一个元素，也无法识别数组边界，
// SSE2 时代更没有 scatter 指令可用，只能保持标量。
void g5_scatter(long* v, const long* idx,
                const long* x, std::size_t n) {
    for (std::size_t i = 0; i < n; ++i) {
        v[idx[i]] += x[i];
    }
}
