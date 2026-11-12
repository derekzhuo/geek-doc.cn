#include "loops.hpp"

// G2：整数归约。long 加法满足结合律，重排不改变结果，
// 编译器可以把标量累加拆成多路向量累加器，循环尾再横向求和。
long g2_isum(const long* a, std::size_t n) {
    long s = 0;
    for (std::size_t i = 0; i < n; ++i) {
        s += a[i];
    }
    return s;
}
