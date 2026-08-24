// main.cpp —— 微基准测试与优化前后对比实验
//
// 一个可优化函数，两个版本：
//   1. 基线版：朴素实现，差缓存局部性（行优先访问列优先矩阵）
//   2. 优化版：改善数据布局（列优先访问列优先矩阵）
//
// 用 perf diff 定量对比优化前后的各函数变化（Delta%）。
//
// 编译: make          → -O2 -std=c++17 -g
//
// 用法:
//   ./perf_bench_diff base       → 只跑基线版
//   ./perf_bench_diff opt        → 只跑优化版
//   ./perf_bench_diff            → 两版全跑 + perf diff 建议
//
// perf 示例:
//   # 录制基线版
//   perf record -o perf_base.data ./perf_bench_diff base
//   # 录制优化版
//   perf record -o perf_opt.data ./perf_bench_diff opt
//   # 对比
//   perf diff perf_base.data perf_opt.data

#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <cstdlib>
#include <cstring>

constexpr int ROWS = 4096;
constexpr int COLS = 4096;
constexpr int TOTAL = ROWS * COLS;  // 16M 个 int = 64MB

// ── 基线版数据布局 ──────────────────────────────────────────
// matrix[row][col] — 标准 C 风格
// 行优先存储: matrix[0][0], matrix[0][1], ..., matrix[0][COLS-1], matrix[1][0], ...
struct MatrixRowMajor {
    int* data;
    MatrixRowMajor() { data = new int[TOTAL](); }
    ~MatrixRowMajor() { delete[] data; }
    int& at(int r, int c) { return data[r * COLS + c]; }
};

// ── 优化版数据布局 ──────────────────────────────────────────
// matrix[col][row] — 列优先存储
// row * COLS + col 变成 col * ROWS + row
// 当外层循环是 col 时，内层 row 遍历就是顺序访问
struct MatrixColMajor {
    int* data;
    MatrixColMajor() { data = new int[TOTAL](); }
    ~MatrixColMajor() { delete[] data; }
    int& at(int r, int c) { return data[c * ROWS + r]; }
};

// ── 基线版: 列遍历行优先矩阵（对缓存最差）───────────────────
// 外层 col, 内层 row → 每次访问跳过 COLS=4096 个 int
// → stride=4096 → 跨越 16KB → 每个 cache line 只用 1 次 → L1 miss 率 ~100%
double bench_baseline() {
    MatrixRowMajor mat;
    volatile long sink = 0;

    auto t0 = std::chrono::high_resolution_clock::now();
    for (int col = 0; col < COLS; col++) {
        for (int row = 0; row < ROWS; row++) {
            sink += mat.at(row, col);  // 列遍历行优先 → cache unfriendly
        }
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    (void)sink;

    double sec = std::chrono::duration<double>(t1 - t0).count();
    return TOTAL / sec / 1e9;  // 吞吐: 亿次访问/秒
}

// ── 优化版: 列遍历列优先矩阵（对缓存友好）────────────────────
// 外层 col, 内层 row → 列优先矩阵中 col 不变 → row 连续
// → stride=1 → 充分利用 cache line → L1 miss 率 ~0%
double bench_optimized() {
    MatrixColMajor mat;
    volatile long sink = 0;

    auto t0 = std::chrono::high_resolution_clock::now();
    for (int col = 0; col < COLS; col++) {
        for (int row = 0; row < ROWS; row++) {
            sink += mat.at(row, col);  // 列遍历列优先 → cache friendly
        }
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    (void)sink;

    double sec = std::chrono::duration<double>(t1 - t0).count();
    return TOTAL / sec / 1e9;
}

int main(int argc, char** argv) {
    std::string mode = (argc >= 2) ? argv[1] : "all";

    std::cout << "\n╔══════════════════════════════════════════════════════════╗\n"
              << "║    微基准测试 + perf diff 优化对比实验                      ║\n"
              << "║  矩阵 " << ROWS << "x" << COLS << " ints = " << (TOTAL * 4 / 1024 / 1024)
              << "MB                               ║\n"
              << "║  遍历: 外层 col, 内层 row                                   ║\n"
              << "╚══════════════════════════════════════════════════════════╝\n\n";

    if (mode == "base" || mode == "all") {
        std::cout << "=== 基线版 (行优先矩阵, 列遍历 — cache unfriendly) ===\n";
        double ops = bench_baseline();
        std::cout << "  吞吐: " << std::fixed << std::setprecision(3)
                  << ops << " 亿次访问/s\n\n";
        if (mode == "base")
            std::cout << "  提示: perf record -o perf_base.data ./perf_bench_diff base\n";
    }

    if (mode == "opt" || mode == "all") {
        std::cout << "=== 优化版 (列优先矩阵, 列遍历 — cache friendly) ===\n";
        double ops = bench_optimized();
        std::cout << "  吞吐: " << std::fixed << std::setprecision(3)
                  << ops << " 亿次访问/s\n\n";
        if (mode == "opt")
            std::cout << "  提示: perf record -o perf_opt.data ./perf_bench_diff opt\n";
    }

    if (mode == "all") {
        std::cout << "\n── perf diff 建议 ──\n\n"
                  << "  # 第一步: 分别录制\n"
                  << "  perf record -o perf_base.data ./perf_bench_diff base\n"
                  << "  perf record -o perf_opt.data  ./perf_bench_diff opt\n\n"
                  << "  # 第二步: 对比\n"
                  << "  perf diff perf_base.data perf_opt.data\n\n"
                  << "  # 第三步: 对比并排序\n"
                  << "  perf diff --sort delta-abs perf_base.data perf_opt.data\n\n"
                  << "  输出解读:\n"
                  << "    Delta%  = (新 - 旧) / 旧 的百分比\n"
                  << "    +50%   → 优化后这个函数消耗更多周期（可能变差了）\n"
                  << "    -80%   → 优化后这个函数消耗更少周期（有效果）\n\n"
                  << "  预期: bench_baseline 的 Delta% 为负大值(优化版消失)\n"
                  << "        bench_optimized 是新出现的（因为 perf diff 无法对齐）\n\n";

        std::cout << "── perf bench (系统微基准) ──\n\n"
                  << "  # 测内存带宽\n"
                  << "  perf bench mem memcpy\n\n"
                  << "  # 测 futex 性能\n"
                  << "  perf bench futex lock-pi\n\n"
                  << "  # 测调度延迟\n"
                  << "  perf bench sched pipe\n"
                  << "  perf bench sched messaging\n\n"
                  << "  提示: perf bench 测的是系统级基础性能，\n"
                  << "  不是你的程序——用于了解机器上限。\n";
    }

    return 0;
}
