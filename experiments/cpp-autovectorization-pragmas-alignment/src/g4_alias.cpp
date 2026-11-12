#include "loops.hpp"

// G4：与 G1 同样的 AXPY，但去掉 restrict。
// 编译器无法证明 a 与 b 不重叠，不能贸然向量化；
// 本工具链的做法是生成两段代码：入口先做运行时区间重叠检查，
// 不重叠才跳进向量版本，重叠则回退标量版本（loop versioning）。
void g4_alias(double* a, double* b, std::size_t n) {
    for (std::size_t i = 0; i < n; ++i) {
        a[i] += b[i];
    }
}
