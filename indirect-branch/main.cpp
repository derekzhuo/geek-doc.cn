// main.cpp —— 间接分支预测实验
//
// 对比四种调用方式的分支预测行为：
//   1. 直接函数调用     → 无间接分支，call 目标已知，零开销
//   2. 单态虚函数       → 间接分支 (call *%rax)，但目标始终不变
//                         CPU 间接分支预测器很快"学会"，准确率 >99%
//   3. 多态虚函数       → 间接分支，目标在每个对象间交替变化
//                         CPU 能预测简单交替模式，准确率仍很高
//   4. 巨态虚函数       → 间接分支，目标完全随机变化
//                         预测器无从学起，准确率大幅下降
//
// 核心原理：
//   - 直接分支 (jcc) 只要猜"跳/不跳"一个 bit
//   - 间接分支 (call *%rax / jmp *%rax) 还要猜**跳转到哪个地址** —— 难得多
//   - 现代 CPU 有专门的 indirect branch predictor 和 ITTAGE 来应对
//   - 单态/少态虚函数：predictor 轻松学会
//   - 巨态虚函数：predictor 抓瞎，每次都是赌
//
// 编译: make
//       make perf              → perf stat 全指标
//       make perf-branch-loads → 只看 branch-loads / branch-load-misses
//
// 用法:
//   ./indirect_branch          → 四种模式耗时对比 + perf 建议

#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <cstdlib>
#include <cstring>
#include <random>
#include <algorithm>

constexpr int N = 4096;          // 对象数量
constexpr int ROUNDS = 10000;    // 每模式重复测量轮数
constexpr int WARMUP = 500;      // 计时前先跑这么多轮预热 (让 iCache + predictor 进入稳态)
constexpr int TRIALS = 5;        // 计时后跑这么多遍取中位数 (避免噪声)

// ── 虚函数类层级 ────────────────────────────────────────────────
// 模拟一个简化的"运算"接口, 类似 FPGA/量化里常见的 kernel dispatch

struct Op {
    virtual ~Op() = default;
    virtual int compute(int x) const = 0;
};

struct OpAdd : Op { int compute(int x) const override { return x + 1; } };
struct OpSub : Op { int compute(int x) const override { return x - 1; } };
struct OpMul : Op { int compute(int x) const override { return x * 2; } };
struct OpShl : Op { int compute(int x) const override { return x << 1; } };

// ── 准备对象数组 ────────────────────────────────────────────────
// 生成 N 个 Op* 指针, 按指定模式分配子类

enum Pattern { MONO, DUAL, MEGA };

std::vector<Op*> make_ops(Pattern p) {
    std::vector<Op*> ops(N);
    switch (p) {
    case MONO:   // 单态: 全部同一种类型
        for (int i = 0; i < N; i++) ops[i] = new OpAdd();
        break;
    case DUAL: { // 双态: 交替 OpAdd / OpSub
        for (int i = 0; i < N; i++)
            ops[i] = (i % 2 == 0) ? (Op*)new OpAdd() : (Op*)new OpSub();
        break;
    }
    case MEGA: { // 巨态: 四种类型随机混排
        std::mt19937 rng(42);
        std::uniform_int_distribution<int> dist(0, 3);
        for (int i = 0; i < N; i++) {
            switch (dist(rng)) {
            case 0: ops[i] = new OpAdd(); break;
            case 1: ops[i] = new OpSub(); break;
            case 2: ops[i] = new OpMul(); break;
            case 3: ops[i] = new OpShl(); break;
            }
        }
        break;
    }
    }
    return ops;
}

void free_ops(std::vector<Op*>& ops) {
    for (auto p : ops) delete p;
}

// ── 测量工具 ────────────────────────────────────────────────────
// 每个 bench 函数都按这个模式:
//   1) warmup: 跑 WARMUP 轮不计时, 让 iCache + branch predictor 进入稳态
//   2) trials: 跑 TRIALS 遍计时, 取中位数 (median), 抗噪声
// 关键原因: 第一个测的模式 iCache 是冷的、predictor 状态为空、CPU 可能尚未睿频;
//          不预热直接计时, 后面的模式会"借光"前面建立好的微架构状态, 数据失真。
//          中位数比平均数更抗偶发中断/调度抖动。

double pick_median(std::vector<double>& v) {
    std::sort(v.begin(), v.end());
    return v[v.size() / 2];
}

// ── 模式1: 直接函数调用 (对照基准) ──────────────────────────────
inline int direct_add(int x) { return x + 1; }

double bench_direct_call() {
    volatile long sum = 0;
    // warmup
    for (int r = 0; r < WARMUP; r++) {
        for (int i = 0; i < N; i++) sum += direct_add(i);
    }
    (void)sum;
    // trials
    std::vector<double> times;
    for (int t = 0; t < TRIALS; t++) {
        volatile long s = 0;
        auto t0 = std::chrono::high_resolution_clock::now();
        for (int r = 0; r < ROUNDS; r++) {
            for (int i = 0; i < N; i++) s += direct_add(i);
        }
        auto t1 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration<double>(t1 - t0).count());
        (void)s;
    }
    return pick_median(times);
}

// ── 模式2: 单态虚函数 ──────────────────────────────────────────
double bench_mono_virtual() {
    auto ops = make_ops(MONO);
    volatile long sum = 0;
    for (int r = 0; r < WARMUP; r++) {
        for (int i = 0; i < N; i++) sum += ops[i]->compute(i);
    }
    (void)sum;
    std::vector<double> times;
    for (int t = 0; t < TRIALS; t++) {
        volatile long s = 0;
        auto t0 = std::chrono::high_resolution_clock::now();
        for (int r = 0; r < ROUNDS; r++) {
            for (int i = 0; i < N; i++) s += ops[i]->compute(i);
        }
        auto t1 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration<double>(t1 - t0).count());
        (void)s;
    }
    free_ops(ops);
    return pick_median(times);
}

// ── 模式3: 双态虚函数 (交替) ────────────────────────────────────
double bench_dual_virtual() {
    auto ops = make_ops(DUAL);
    volatile long sum = 0;
    for (int r = 0; r < WARMUP; r++) {
        for (int i = 0; i < N; i++) sum += ops[i]->compute(i);
    }
    (void)sum;
    std::vector<double> times;
    for (int t = 0; t < TRIALS; t++) {
        volatile long s = 0;
        auto t0 = std::chrono::high_resolution_clock::now();
        for (int r = 0; r < ROUNDS; r++) {
            for (int i = 0; i < N; i++) s += ops[i]->compute(i);
        }
        auto t1 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration<double>(t1 - t0).count());
        (void)s;
    }
    free_ops(ops);
    return pick_median(times);
}

// ── 模式4: 巨态虚函数 (随机混排) ────────────────────────────────
double bench_mega_virtual() {
    auto ops = make_ops(MEGA);
    volatile long sum = 0;
    for (int r = 0; r < WARMUP; r++) {
        for (int i = 0; i < N; i++) sum += ops[i]->compute(i);
    }
    (void)sum;
    std::vector<double> times;
    for (int t = 0; t < TRIALS; t++) {
        volatile long s = 0;
        auto t0 = std::chrono::high_resolution_clock::now();
        for (int r = 0; r < ROUNDS; r++) {
            for (int i = 0; i < N; i++) s += ops[i]->compute(i);
        }
        auto t1 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration<double>(t1 - t0).count());
        (void)s;
    }
    free_ops(ops);
    return pick_median(times);
}

// ── 模式5: 函数指针 ─────────────────────────────────────────────
double bench_funcptr(const char* label, std::vector<int(*)(int)> fptrs) {
    const int M = (int)fptrs.size();
    volatile long sum = 0;
    for (int r = 0; r < WARMUP; r++) {
        for (int i = 0; i < N; i++) sum += fptrs[i % M](i);
    }
    (void)sum;
    std::vector<double> times;
    for (int t = 0; t < TRIALS; t++) {
        volatile long s = 0;
        auto t0 = std::chrono::high_resolution_clock::now();
        for (int r = 0; r < ROUNDS; r++) {
            for (int i = 0; i < N; i++) s += fptrs[i % M](i);
        }
        auto t1 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration<double>(t1 - t0).count());
        (void)s;
    }
    (void)label;
    return pick_median(times);
}

// ── 模式6: switch 跳转表 ────────────────────────────────────────
int switch_dispatch(int op, int x) {
    switch (op) {
    case 0: return x + 1;
    case 1: return x - 1;
    case 2: return x * 2;
    case 3: return x << 1;
    case 4: return x >> 1;
    default: return x;
    }
}

double bench_switch_sequential() {
    volatile long sum = 0;
    for (int r = 0; r < WARMUP; r++) {
        for (int i = 0; i < N; i++) sum += switch_dispatch(i % 5, i);
    }
    (void)sum;
    std::vector<double> times;
    for (int t = 0; t < TRIALS; t++) {
        volatile long s = 0;
        auto t0 = std::chrono::high_resolution_clock::now();
        for (int r = 0; r < ROUNDS; r++) {
            for (int i = 0; i < N; i++) s += switch_dispatch(i % 5, i);
        }
        auto t1 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration<double>(t1 - t0).count());
        (void)s;
    }
    return pick_median(times);
}

double bench_switch_random() {
    std::mt19937 rng(42);
    std::uniform_int_distribution<int> dist(0, 4);
    volatile long sum = 0;
    for (int r = 0; r < WARMUP; r++) {
        for (int i = 0; i < N; i++) sum += switch_dispatch(dist(rng), i);
    }
    (void)sum;
    std::vector<double> times;
    for (int t = 0; t < TRIALS; t++) {
        volatile long s = 0;
        auto t0 = std::chrono::high_resolution_clock::now();
        for (int r = 0; r < ROUNDS; r++) {
            for (int i = 0; i < N; i++) s += switch_dispatch(dist(rng), i);
        }
        auto t1 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration<double>(t1 - t0).count());
        (void)s;
    }
    return pick_median(times);
}

// ── 运行所有模式（默认行为）─────────────────────────────────────
void run_all() {
    std::cout << "\n╔══════════════════════════════════════════════════════════╗\n"
              << "║       间接分支预测实验 (Indirect Branch Prediction)       ║\n"
              << "║  对象 N=" << N << ", 每轮 " << ROUNDS << " 遍                            ║\n"
              << "║  焦点: branch-loads / branch-load-misses                 ║\n"
              << "╚══════════════════════════════════════════════════════════╝\n\n";

    auto print_row = [](const char* name, double t, double baseline) {
        std::cout << std::left << std::setprecision(2)
                  << std::setw(30) << name
                  << std::setw(14) << (t * 1e3)
                  << std::setw(12) << (t / baseline * 100.0) << "%\n";
    };

    // ── 虚函数部分 ────────────────────────────────────────────
    std::cout << "── 虚函数调用 (vtable dispatch) ──\n\n"
              << "  正在测量...  \n";

    double t_direct  = bench_direct_call();
    double t_mono    = bench_mono_virtual();
    double t_dual    = bench_dual_virtual();
    double t_mega    = bench_mega_virtual();

    std::cout << std::left << std::fixed
              << std::setw(30) << "模式"
              << std::setw(14) << "耗时(ms)"
              << std::setw(14) << "相对(%)\n"
              << std::string(58, '-') << '\n';

    double baseline = t_direct;

    print_row("直接调用 (direct call)",   t_direct, baseline);
    print_row("单态虚函数 (monomorphic)",  t_mono,   baseline);
    print_row("双态虚函数 (bimorphic)",    t_dual,   baseline);
    print_row("巨态虚函数 (megamorphic)",  t_mega,   baseline);

    std::cout << "\n  ── 观察要点 ──\n\n"
              << "  ▸ 直接调用: call 目标地址编码在指令里, 无间接分支\n"
              << "  ▸ 单态虚函数: 通过 vtable 间接跳转 (call *%rax),\n"
              << "    但每次目标相同 → indirect predictor 学会后几乎零开销\n"
              << "  ▸ 双态虚函数: 两个目标交替 → predictor 能学交替模式,\n"
              << "    比单态稍慢但接近\n"
              << "  ▸ 巨态虚函数: 四个目标随机 → predictor 无法学习,\n"
              << "    每次 ~50%+ 概率猜错, 显著变慢\n\n";

    // ── 函数指针部分 ──────────────────────────────────────────
    std::cout << "── 函数指针调用 ──\n\n"
              << "  正在测量...  \n";

    std::vector<int(*)(int)> mono_fptrs = { direct_add };
    std::vector<int(*)(int)> mega_fptrs = {
        [](int x) -> int { return x + 1; },
        [](int x) -> int { return x - 1; },
        [](int x) -> int { return x * 2; },
        [](int x) -> int { return x << 1; },
    };

    double t_fp_single = bench_funcptr("单目标函数指针", mono_fptrs);
    double t_fp_multi  = bench_funcptr("多目标函数指针", mega_fptrs);

    std::cout << std::left << std::fixed
              << std::setw(30) << "模式"
              << std::setw(14) << "耗时(ms)"
              << std::setw(14) << "相对(单目标%)\n"
              << std::string(58, '-') << '\n';

    print_row("函数指针(单一目标)", t_fp_single, t_fp_single);
    print_row("函数指针(四目标轮转)", t_fp_multi, t_fp_single);

    std::cout << "\n  ── 观察要点 ──\n\n"
              << "  ▸ 函数指针 = 间接 call, 和虚函数本质一样\n"
              << "  ▸ 单一目标: predictor 学会, 接近直接调用\n"
              << "  ▸ 多目标: 取决于目标地址在间接分支预测器中的别名冲突\n\n";

    // ── switch 跳转表部分 ─────────────────────────────────────
    std::cout << "── switch 跳转表 ──\n\n"
              << "  正在测量...  \n";

    double t_sw_seq = bench_switch_sequential();
    double t_sw_rnd = bench_switch_random();

    std::cout << std::left << std::fixed
              << std::setw(30) << "模式"
              << std::setw(14) << "耗时(ms)"
              << std::setw(14) << "相对(%)\n"
              << std::string(58, '-') << '\n';

    print_row("switch(顺序 op)", t_sw_seq, t_sw_seq);
    print_row("switch(随机 op)", t_sw_rnd, t_sw_seq);

    std::cout << "\n  ── 观察要点 ──\n\n"
              << "  ▸ switch 密集连续值 → 编译成跳转表 (jmp *disp(,%rax,8))\n"
              << "    本质是间接分支, 也受 indirect predictor 影响\n"
              << "  ▸ 顺序 op: predictor 可能学到大步进模式\n"
              << "  ▸ 随机 op: 预测失败率上升, 变慢\n\n";

    // ── perf 建议命令 ──────────────────────────────────────────
    std::cout << "── perf 建议命令 ──\n\n"
              << "  # 用 --mode 单独跑一个模式, 避免各种模式混在一起:\n"
              << "  perf stat -e branch-loads,branch-load-misses \\\n"
              << "      ./indirect_branch --mode mono\n\n"
              << "  perf stat -e branch-loads,branch-load-misses \\\n"
              << "      ./indirect_branch --mode mega\n\n"
              << "  # perf record 定位具体函数 (同样建议 --mode 隔离):\n"
              << "  perf record -e branch-load-misses:pp -g \\\n"
              << "      ./indirect_branch --mode mega\n"
              << "  perf report --stdio\n"
              << "  # 进入热点函数后: perf annotate\n\n"
              << "  # 预期结果:\n"
              << "  #   单态虚函数 → branch-load-misses 很低\n"
              << "  #   巨态虚函数 → branch-load-misses 显著升高\n"
              << "  #   巨态间接分支预测失败比条件分支 (jcc) 更难优化\n\n"
              << "   核心结论: 间接分支 (虚函数/函数指针/switch 跳转表)\n"
              << "   不仅要猜方向, 还要猜目标地址, 比条件分支更难预测。\n"
              << "   单态/少态 → predictor 学会, 几乎零开销;\n"
              << "   巨态/随机 → predictor 抓瞎, 考虑去虚化或分支打散。\n";
}

// ── main ────────────────────────────────────────────────────────
int main(int argc, char** argv) {
    const char* mode = "all";
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--mode") == 0 && i + 1 < argc)
            mode = argv[++i];
        else if (strcmp(argv[i], "-m") == 0 && i + 1 < argc)
            mode = argv[++i];
    }

    if (strcmp(mode, "direct") == 0) {
        bench_direct_call();
        return 0;
    }
    if (strcmp(mode, "mono") == 0) {
        bench_mono_virtual();
        return 0;
    }
    if (strcmp(mode, "dual") == 0) {
        bench_dual_virtual();
        return 0;
    }
    if (strcmp(mode, "mega") == 0) {
        bench_mega_virtual();
        return 0;
    }
    if (strcmp(mode, "fptr-single") == 0) {
        std::vector<int(*)(int)> mono_fptrs = { direct_add };
        bench_funcptr("单目标函数指针", mono_fptrs);
        return 0;
    }
    if (strcmp(mode, "fptr-multi") == 0) {
        std::vector<int(*)(int)> mega_fptrs = {
            [](int x) -> int { return x + 1; },
            [](int x) -> int { return x - 1; },
            [](int x) -> int { return x * 2; },
            [](int x) -> int { return x << 1; },
        };
        bench_funcptr("多目标函数指针", mega_fptrs);
        return 0;
    }
    if (strcmp(mode, "switch-seq") == 0) {
        bench_switch_sequential();
        return 0;
    }
    if (strcmp(mode, "switch-rnd") == 0) {
        bench_switch_random();
        return 0;
    }
    if (strcmp(mode, "all") != 0) {
        std::cerr << "未知模式: " << mode << "\n"
                  << "用法: ./indirect_branch [--mode <模式>]\n"
                  << "  模式: direct | mono | dual | mega |\n"
                  << "        fptr-single | fptr-multi | switch-seq | switch-rnd | all\n";
        return 1;
    }

    run_all();
    return 0;
}
