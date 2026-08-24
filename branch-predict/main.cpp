// main.cpp —— 分支预测实验
//
// 对比 3 种写法在有序/随机数据上的分支预测行为：
//   1. 有序数据 + if 分支     → 分支规律，预测成功率高，快
//   2. 随机数据 + if 分支     → 分支无规律，预测失败率高，慢
//   3. 随机数据 + 无分支写法   → 用算术替代分支，平稳但不如"有序+if"快
//
// 核心原理：CPU 的分支预测器本质是"模式识别器"。
//   有序数据 → "全是 true → 全是 false"的突然转折，只需 1~2 次误判
//   随机数据 → true/false 完全随机，预测器无法学习，每次 ~50% 误判
//
// 编译: make          → -O2（-O2 下 cmov 可能自动优化掉分支，正好观察）
//       make no-cmov  → -O2 -fno-if-conversion（关闭 cmov，强制用真实分支）
//                        —— 对比两版的 branch-misses 差异，直观理解编译器自动优化
//
// 用法:
//   ./branch_predict            → 全部模式对比表 + perf 建议
//
// perf 示例:
//   perf stat -e cycles,instructions,branch-instructions,branch-misses ./branch_predict
//   perf stat -e branch-loads,branch-load-misses ./branch_predict
//   # 汇编级对比: 看哪个指令的分支预测失败最多
//   perf record -e branch-misses:pp -g ./branch_predict && perf annotate

#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <cstdlib>
#include <algorithm>
#include <random>

constexpr int N = 32768;       // 元素数
constexpr int ROUNDS = 1000;   // 每轮重复测量次数

// ── 准备数据 ──────────────────────────────────────────────────
std::vector<int> make_ordered() {
    std::vector<int> v(N);
    for (int i = 0; i < N; i++) v[i] = i;
    return v;
}

std::vector<int> make_random() {
    std::vector<int> v(N);
    for (int i = 0; i < N; i++) v[i] = i;
    std::mt19937 rng(42);
    std::shuffle(v.begin(), v.end(), rng);
    return v;
}

// ── 模式1: 有序数据 + 有分支 ──────────────────────────────────
double bench_ordered_branch() {
    auto data = make_ordered();
    volatile long sum = 0;
    auto t0 = std::chrono::high_resolution_clock::now();
    for (int r = 0; r < ROUNDS; r++) {
        for (int i = 0; i < N; i++) {
            if (data[i] >= N / 2)   // 前半段 false, 后半段 true, 非常规律
                sum += data[i];
        }
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    (void)sum;
    double sec = std::chrono::duration<double>(t1 - t0).count();
    return ROUNDS * N / sec / 1e9;  // 吞吐: 亿次判断/秒
}

// ── 模式2: 随机数据 + 有分支 ──────────────────────────────────
double bench_random_branch() {
    auto data = make_random();
    volatile long sum = 0;
    auto t0 = std::chrono::high_resolution_clock::now();
    for (int r = 0; r < ROUNDS; r++) {
        for (int i = 0; i < N; i++) {
            if (data[i] >= N / 2)   // true/false 完全随机
                sum += data[i];
        }
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    (void)sum;
    double sec = std::chrono::duration<double>(t1 - t0).count();
    return ROUNDS * N / sec / 1e9;
}

// ── 模式3: 随机数据 + 无分支写法 ─────────────────────────────
// 用算术运算替代分支: sum += (cond ? val : 0) → sum += val * (cond)
double bench_random_branchless() {
    auto data = make_random();
    volatile long sum = 0;
    auto t0 = std::chrono::high_resolution_clock::now();
    for (int r = 0; r < ROUNDS; r++) {
        for (int i = 0; i < N; i++) {
            // 算术替代: (data[i] >= N/2) → 0 或 1
            // 等价于 if(data[i]>=N/2) sum+=data[i] 但没有真实分支指令
            int mask = (data[i] >= N / 2) ? -1 : 0;  // 仍含分支，展示概念用
            // 真正的无分支: sum += (data[i] >= N/2) ? data[i] : 0;
            // 编译器在 -O2 下通常自动生成 cmov / setg + and
            sum += data[i] & mask;
        }
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    (void)sum;
    double sec = std::chrono::duration<double>(t1 - t0).count();
    return ROUNDS * N / sec / 1e9;
}

// ── main ─────────────────────────────────────────────────────
int main() {
    std::vector<double> ops(3);

    std::cout << "\n╔══════════════════════════════════════════════════════════╗\n"
              << "║           分支预测实验                                    ║\n"
              << "║  数组 N=" << N << " 元素, 每轮 " << ROUNDS << " 遍                                ║\n"
              << "║  判断: if(data[i] >= N/2) → 50% true, 50% false          ║\n"
              << "╚══════════════════════════════════════════════════════════╝\n\n";

    std::cout << "  正在测量...\n";

    ops[0] = bench_ordered_branch();
    ops[1] = bench_random_branch();
    ops[2] = bench_random_branchless();

    double baseline = ops[0];

    std::cout << std::left << std::fixed
              << '\n'
              << std::setw(26) << "模式"
              << std::setw(18) << "吞吐(亿次/s)"
              << std::setw(12) << "相对(%)\n";
    std::cout << std::string(56, '-') << '\n';

    const char* names[3] = {
        "有序数据 + if 分支",
        "随机数据 + if 分支",
        "随机数据 + 无分支(算术)"
    };

    for (int i = 0; i < 3; i++) {
        double pct = (ops[i] / baseline) * 100.0;
        std::cout << std::left << std::setprecision(3)
                  << std::setw(26) << names[i]
                  << std::setw(18) << ops[i]
                  << std::setw(10) << std::setprecision(1) << pct << "%\n";
    }

    std::cout << "\n── 观察要点 ──\n\n"
              << "   ▸ 有序+if: 分支预测成功率 >99%, 流水线几乎不空转, 最快\n"
              << "   ▸ 随机+if: 分支预测失败率 ~50%, 每次误判冲刷流水线 ~15-20 拍\n"
              << "              表现显著慢于有序版 (通常慢 2~5x)\n"
              << "   ▸ 无分支:   没有分支指令 = 没有预测失败, 表现稳定\n"
              << "              但多了算术指令, 有序版用 if 反而可能更快\n\n"
              << "   核心结论: 分支预测器是模式识别器, 规律的分支几乎零开销;\n"
              << "   不规律的分支 → 考虑用无分支写法或排序数据。\n\n";

    std::cout << "── perf 建议命令 ──\n\n"
              << "  # 基础对比 (一次跑完三种, 看整体 branch-misses)\n"
              << "  perf stat -e cycles,instructions,branch-instructions,\\\n"
              << "branch-misses ./branch_predict\n\n"
              << "  # 汇编级定位: 哪个指令的 branch-misses 最多?\n"
              << "  perf record -e branch-misses:pp -g ./branch_predict\n"
              << "  perf report --stdio\n"
              << "  # 进入某个函数的反汇编\n"
              << "  perf annotate\n\n"
              << "  # 对比 -O2 有无 cmov 自动优化\n"
              << "  perf stat -e branch-instructions,branch-misses \\\n"
              << "      ./branch_predict\n"
              << "  # vs\n"
              << "  make no-cmov\n"
              << "  perf stat -e branch-instructions,branch-misses \\\n"
              << "      ./branch_predict_no_cmov\n\n"
              << "  # 预期: no-cmov 版 branch-misses 在随机数据上高 ~50%\n"
              << "  # -O2 默认版编译器已用 cmov 自动优化掉分支\n";

    return 0;
}
