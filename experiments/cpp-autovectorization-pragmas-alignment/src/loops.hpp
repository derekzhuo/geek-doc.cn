#ifndef VEC_LOOPS_HPP
#define VEC_LOOPS_HPP

#include <cstddef>
#include <cstdint>

// 全部测量函数固定 noinline：防止被内联进 main 后与相邻代码联合优化，
// 保证 -Rpass 报告、反汇编与计时都能按函数逐个核对。
#define NOINLINE __attribute__((noinline))

// G1 可向量化基线：restrict 双指针 AXPY，元素间无依赖
NOINLINE void g1_axpy_restrict(double* __restrict a,
                               const double* __restrict b,
                               double s, std::size_t n);

// G2 整数归约：整数加法满足结合律，普通 -O2 即可向量化
NOINLINE long g2_isum(const long* a, std::size_t n);

// G3 反向循环携带依赖：a[i] 依赖 a[i-1]，向量化硬阻
NOINLINE void g3_recurrence(double* a, std::size_t n);

// G4 裸双指针（可别名）：编译器插运行时别名检查，走版本化向量化
NOINLINE void g4_alias(double* a, double* b, std::size_t n);

// G5 分散写：下标运行时才知道，无法识别数组边界，向量化硬阻
NOINLINE void g5_scatter(long* v, const long* idx,
                         const long* x, std::size_t n);

// G6 浮点归约严格模式：-O2 不敢改变浮点求和顺序
NOINLINE double g6_fpsum_strict(const double* a, std::size_t n);

// G7 同一浮点归约加 pragma，显式允许重排后向量化
NOINLINE double g7_fpsum_pragma(const double* a, std::size_t n);

// G8 对齐干预：64 字节对齐 + 显式对齐承诺，对照 8 字节错位缓冲
NOINLINE double g8_aligned_sum(const double* a, std::size_t n);
NOINLINE double g8_misaligned_sum(const double* a, std::size_t n);

// G9 循环展开干预：朴素整数归约对照 unroll_count(8)
NOINLINE long g9_isum_plain(const long* a, std::size_t n);
NOINLINE long g9_isum_unroll(const long* a, std::size_t n);

#endif
