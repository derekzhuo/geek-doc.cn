// main.cpp —— CPU 流水线停顿模式实验
//
// 4 种典型停顿模式，用 perf stat 的 stalled-cycles-* 事件区分根因：
//   模式1 纯计算      —— 对照组：前后端停顿都低，IPC 高
//   模式2 函数指针间接调用 —— 前端停顿：I-cache miss + 分支目标预测失败
//   模式3 随机内存访问    —— 后端停顿：D-cache miss，ALU 空等数据
//   模式4 长依赖链        —— 后端停顿：数据依赖，ALU 必须串行
//
// 区分"前端 vs 后端"是 micro-benchmarking 的分叉口：
//   前端 = 喂不饱流水线（取指不够快 / 分支预测失败 / I-cache miss）
//   后端 = 流水线满了但在等（D-cache miss / 长依赖链 / 执行单元忙）
//
// 编译: make          → -O2（保持基本优化，但避免编译器消除关键循环）
//
// 用法:
//   ./stall_analysis 1     → 纯计算
//   ./stall_analysis 2     → 函数指针间接调用
//   ./stall_analysis 3     → 随机内存访问
//   ./stall_analysis 4     → 长数据依赖链
//   ./stall_analysis        → 全部模式自动对比
//
// perf 示例（核心命令）:
//   perf stat -e cycles,instructions,\
//       stalled-cycles-frontend,stalled-cycles-backend,\
//       L1-icache-load-misses,\
//       branch-misses,\
//       cache-references,cache-misses \
//       ./stall_analysis 1

#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <cstdlib>
#include <random>

constexpr int N       = 16 * 1024 * 1024;  // 16M 元素
constexpr int ITERS   = N / 4;              // 操作次数
constexpr int SECONDS = 3;                  // 每个模式最少跑 x 秒

// ── 工具：跑满指定秒数后返回吞吐 ────────────────────────────
template<typename Func>
double bench_seconds(const char* name, Func fn) {
    std::cout << "  正在测量 " << name << " ..." << std::flush;

    volatile long sink = 0;
    long      total   = 0;
    auto t0 = std::chrono::high_resolution_clock::now();

    while (true) {
        fn(sink);
        total += ITERS;
        auto now = std::chrono::high_resolution_clock::now();
        if (std::chrono::duration<double>(now - t0).count() >= SECONDS)
            break;
    }

    auto   t1   = std::chrono::high_resolution_clock::now();
    double secs = std::chrono::duration<double>(t1 - t0).count();
    (void)sink;

    std::cout << " 完成 (" << std::fixed << std::setprecision(1)
              << secs << "s, " << (total / secs / 1e9)
              << " 亿次/秒)\n";

    return total / secs / 1e9;
}

// ── 模式1: 纯计算（对照组）───────────────────────────────────
// 特点：热数据全在寄存器，无内存访问，无分支，无依赖链
// 预期：前端停顿 <5%, 后端停顿 <5%, IPC 高 (>2.5)
void run_compute(volatile long& sink) {
    volatile long a = 1, b = 2, c = 3, d = 4;
    for (int i = 0; i < ITERS; i++) {
        // 简单算术，无数据依赖，CPU 可乱序并行
        a = a + b;
        b = b + c;
        c = c + d;
        d = d + a;
    }
    sink = a + b + c + d;
}

// ── 模式2: 函数指针间接调用（前端停顿）───────────────────────
// 特点：通过函数指针数组做间接跳转，分支目标预测器难以学习
// 预期：前端停顿 30~50%+, I-cache miss + 间接分支预测失败
using VoidFn = void (*)(volatile long&);

void add1(volatile long& x) { x += 1; }
void sub1(volatile long& x) { x -= 1; }
void mul2(volatile long& x) { x *= 2; }
void div2(volatile long& x) { x /= 2; }
void xor1(volatile long& x) { x ^= 1; }
void shl1(volatile long& x) { x <<= 1; }
void shr1(volatile long& x) { x >>= 1; }
void inc3(volatile long& x) { x += 3; }

VoidFn fns[] = {add1, sub1, mul2, div2, xor1, shl1, shr1, inc3, add1, sub1,
                mul2, div2, xor1, shl1, shr1, inc3};
constexpr int NFNS = sizeof(fns) / sizeof(fns[0]);

void run_indirect_calls(volatile long& sink) {
    volatile long v = 42;
    for (int i = 0; i < ITERS; i++) {
        fns[i % NFNS](v);   // 间接调用，目标每轮都变
    }
    sink = v;
}

// ── 模式3: 随机内存访问（后端停顿 - D-cache miss）───────────
// 特点：随机数组索引 → L1/L2 miss → ALU 空等数据从 DRAM 返回
// 预期：后端停顿 40~70%+
void run_random_mem(volatile long& sink) {
    static std::vector<int> arr(N);

    if (arr[0] == 0 && arr[1] == 0) {    // 懒初始化
        // 预生成随机索引
        std::mt19937 rng(42);
        for (size_t i = 0; i < arr.size(); i++)
            arr[i] = rng();
    }

    volatile long sum = 0;
    size_t idx = 0;
    for (int i = 0; i < ITERS; i++) {
        // idx = arr[idx] 创建了一个指针追踪链，
        // 每次访问都依赖上一次的结果（数据依赖），
        // 这阻止了 CPU 的硬件预取器
        idx = static_cast<size_t>(arr[idx % N]) % N;
        sum += arr[idx];
    }
    sink = sum;
}

// ── 模式4: 长数据依赖链（后端停顿 - 依赖链）───────────────────
// 特点：每次运算依赖前一次的结果，CPU 无法乱序并行
// 预期：后端停顿 30~50%+, IPC 被依赖链长度限制
void run_dependency_chain(volatile long& sink) {
    volatile long a = 1;
    for (int i = 0; i < ITERS; i++) {
        // a 的每次更新都依赖上一次的 a 值
        // CPU 的 ALU latency (~4 cycles) 成为瓶颈
        a = a * 13 + 7;
    }
    sink = a;
}

// ── 打印单模式 perf 建议 ─────────────────────────────────────
void print_perf_hints(int mode) {
    std::cout << "\n── perf 建议命令 (模式" << mode << ") ──\n\n"
              << "  # 全景: 停顿占比 + 缓存 + 分支\n"
              << "  perf stat -e cycles,instructions,\\\n"
              << "      stalled-cycles-frontend,stalled-cycles-backend,\\\n"
              << "      L1-icache-load-misses,branch-misses,\\\n"
              << "      cache-references,cache-misses \\\n"
              << "      ./stall_analysis " << mode << "\n\n"
              << "  # 解读:\n";
    switch (mode) {
    case 1:
        std::cout << "  #   预期: IPC >2.5, frontend/backend 停顿都 <5%\n"
                  << "  #   这是\"高性能程序\"的理想状态\n";
        break;
    case 2:
        std::cout << "  #   预期: IPC <1.0, frontend 停顿 30~50%+\n"
                  << "  #   I-cache miss 和 branch-misses 都偏高\n"
                  << "  #   诊断: 前端喂不饱流水线 → 代码布局或间接跳转问题\n";
        break;
    case 3:
        std::cout << "  #   预期: IPC <0.5, backend 停顿 40~70%+\n"
                  << "  #   cache-misses 极高, LLC-load-misses 也高\n"
                  << "  #   诊断: 数据瓶颈 → 改数据布局、预取或减少随机访问\n";
        break;
    case 4:
        std::cout << "  #   预期: IPC ~0.25 (受 ALU latency ~4 cycles 限制)\n"
                  << "  #   backend 停顿 30~50%+, 但 cache-misses 低\n"
                  << "  #   诊断: 依赖链瓶颈 → 需重构算法打破依赖\n";
        break;
    }
}

// ── main ─────────────────────────────────────────────────────
int main(int argc, char** argv) {
    int mode = 0;  // 0 = 全部
    if (argc >= 2) {
        mode = std::atoi(argv[1]);
        if (mode < 0 || mode > 4) {
            std::cerr << "模式: 1=纯计算 2=间接调用 3=随机访存 4=依赖链\n"
                      << "无参数 → 全部模式自动对比\n";
            return 1;
        }
    }

    std::cout << "\n╔══════════════════════════════════════════════════════════╗\n"
              << "║        CPU 流水线停顿模式实验                               ║\n"
              << "║   每组最少跑 " << SECONDS << " 秒, 确保 perf 有足够采样                 ║\n"
              << "╚══════════════════════════════════════════════════════════╝\n\n";

    if (mode == 1) {
        bench_seconds("模式1 纯计算", run_compute);
        print_perf_hints(1);
    } else if (mode == 2) {
        bench_seconds("模式2 函数指针间接调用", run_indirect_calls);
        print_perf_hints(2);
    } else if (mode == 3) {
        bench_seconds("模式3 随机内存访问", run_random_mem);
        print_perf_hints(3);
    } else if (mode == 4) {
        bench_seconds("模式4 长依赖链", run_dependency_chain);
        print_perf_hints(4);
    } else {
        // 全部模式对比
        struct { const char* name; void (*fn)(volatile long&); int m; }
        tests[] = {
            {"模式1 纯计算",               run_compute,         1},
            {"模式2 函数指针间接调用",       run_indirect_calls, 2},
            {"模式3 随机内存访问",           run_random_mem,     3},
            {"模式4 长数据依赖链",           run_dependency_chain,4},
        };

        std::cout << std::left
                  << std::setw(30) << "模式"
                  << std::setw(16) << "吞吐(亿次/s)\n";
        std::cout << std::string(46, '-') << '\n';

        for (auto& t : tests) {
            double ops = bench_seconds(t.name, t.fn);
            char label[64];
            snprintf(label, sizeof(label), "模式%d %s", t.m, t.name + 7);
            std::cout << std::left << std::setprecision(3)
                      << std::setw(30) << label
                      << std::setw(16) << ops << '\n';
        }

        std::cout << "\n── 诊断指南 ──\n\n"
                  << "  用 perf stat 跑各模式, 对比:\n"
                  << "    stalled-cycles-frontend / cycles   → 前端停顿占比\n"
                  << "    stalled-cycles-backend  / cycles   → 后端停顿占比\n\n"
                  << "  ▸ frontend >30%, 找: I-cache miss / 分支预测失败\n"
                  << "  ▸ backend  >30%, 找: D-cache miss / 长依赖链\n"
                  << "  ▸ 两者都低 (<10%), IPC 高 → 程序已经是\"计算密集型\"理想态\n\n"
                  << "  逐个跑:\n"
                  << "    for m in 1 2 3 4; do\n"
                  << "      echo \"=== 模式\$m ===\"\n"
                  << "      perf stat -e cycles,instructions,\\\\\n"
                  << "        stalled-cycles-frontend,stalled-cycles-backend \\\\\n"
                  << "        ./stall_analysis \$m\n"
                  << "    done\n";
    }

    return 0;
}
