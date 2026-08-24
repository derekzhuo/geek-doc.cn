// main.cpp —— 缓存未命中模式实验
//
// 对比 3 种数组遍历模式对 L1/LLC 缓存命中率的影响：
//   1. 顺序访问：a[i] — 对缓存最友好
//   2. 随机访问：a[rand_idx] — 对缓存最不友好
//   3. 跨步访问：a[i*stride] — stride 越大缓存效率越差
//
// 编译: make          → -O2（让计算效率差异源于访存模式，而非编译优化程度）
//       make release  → -O2 -DNDEBUG（去掉断言，纯粹测硬）
//
// 用法:
//   ./cache_miss seq          → 顺序访问
//   ./cache_miss rand         → 随机访问（L1 miss 率最高）
//   ./cache_miss stride 16    → stride=16 跨步访问
//   ./cache_miss stride 64    → stride=64（常见 cache line 对齐步长）
//   ./cache_miss stride 256   → stride=256（跨越多个 cache line）
//   ./cache_miss               → 自动跑全部模式并打印对比表
//
// perf 示例:
//   perf stat -e cycles,instructions,cache-references,cache-misses ./cache_miss seq
//   perf stat -e cycles,instructions,L1-dcache-loads,L1-dcache-load-misses ./cache_miss rand
//   perf stat -e cycles,instructions,LLC-loads,LLC-load-misses ./cache_miss stride 256

#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <cstdlib>
#include <cstring>
#include <algorithm>
#include <random>

constexpr int N = 16 * 1024 * 1024;  // 16M 个 int = 64MB，超 L3 缓存（典型 ~30-50MB）
constexpr int OPS = N / 2;            // 每次模式做 N/2 次自增，足够暴露差异

// ── 模式1: 顺序访问 ──────────────────────────────────────────
double bench_sequential() {
    std::vector<int> a(N, 0);
    volatile int sink = 0;
    auto t0 = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < OPS; i++)
        a[i]++;
    auto t1 = std::chrono::high_resolution_clock::now();
    sink = a[0];
    (void)sink;
    double sec = std::chrono::duration<double>(t1 - t0).count();
    return OPS / sec / 1e9;  // 吞吐: 亿次自增/秒
}

// ── 模式2: 随机访问 ──────────────────────────────────────────
double bench_random() {
    std::vector<int> a(N, 0);
    // 预生成随机索引序列，避免 rand() 开销影响测量
    std::vector<int> indices(OPS);
    std::mt19937 rng(42);
    std::uniform_int_distribution<int> dist(0, N - 1);
    for (int i = 0; i < OPS; i++)
        indices[i] = dist(rng);

    volatile int sink = 0;
    auto t0 = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < OPS; i++)
        a[indices[i]]++;
    auto t1 = std::chrono::high_resolution_clock::now();
    sink = a[0];
    (void)sink;
    double sec = std::chrono::duration<double>(t1 - t0).count();
    return OPS / sec / 1e9;
}

// ── 模式3: 跨步访问 ──────────────────────────────────────────
double bench_strided(int stride) {
    std::vector<int> a(N, 0);
    volatile int sink = 0;
    auto t0 = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < OPS; i++)
        a[(static_cast<int64_t>(i) * stride) % N]++;
    auto t1 = std::chrono::high_resolution_clock::now();
    sink = a[0];
    (void)sink;
    double sec = std::chrono::duration<double>(t1 - t0).count();
    return OPS / sec / 1e9;
}

// ── 打印单次结果 ────────────────────────────────────────────
void print_one(const char* label, double ops) {
    std::cout << "  模式: " << label << '\n'
              << "  吞吐: " << std::fixed << std::setprecision(3)
              << ops << " 亿次自增/秒\n";
}

// ── 打印 perf 建议 ──────────────────────────────────────────
void print_perf_hint(const char* mode, const char* extra_args = nullptr) {
    std::cout << "\n── perf 建议命令 ──\n\n"
              << "  # 基础对比\n"
              << "  perf stat -e cycles,instructions,cache-references,cache-misses \\\n"
              << "      ./cache_miss " << mode;
    if (extra_args) std::cout << " " << extra_args;
    std::cout << "\n\n"
              << "  # L1 数据缓存\n"
              << "  perf stat -e L1-dcache-loads,L1-dcache-load-misses \\\n"
              << "      ./cache_miss " << mode;
    if (extra_args) std::cout << " " << extra_args;
    std::cout << "\n\n"
              << "  # 最后一级缓存 (LLC)\n"
              << "  perf stat -e LLC-loads,LLC-load-misses \\\n"
              << "      ./cache_miss " << mode;
    if (extra_args) std::cout << " " << extra_args;
    std::cout << '\n';
}

// ── 全量对比表 ──────────────────────────────────────────────
void run_full_compare() {
    struct Result {
        const char* mode;
        double ops;
    };

    Result results[] = {
        {"顺序访问",     bench_sequential()},
        {"stride=2",    bench_strided(2)},
        {"stride=8",    bench_strided(8)},
        {"stride=16",   bench_strided(16)},
        {"stride=64",   bench_strided(64)},
        {"stride=256",  bench_strided(256)},
        {"stride=1024", bench_strided(1024)},
        {"随机访问",     bench_random()},
    };

    double baseline = results[0].ops;

    std::cout << "\n╔══════════════════════════════════════════════════════════╗\n"
              << "║         缓存未命中模式对比实验                              ║\n"
              << "║  数组 N=" << N << " ints = " << (N * 4 / 1024 / 1024)
              << "MB (>典型LLC)                  ║\n"
              << "║  每组操作 = " << OPS << " 次自增                               ║\n"
              << "╚══════════════════════════════════════════════════════════╝\n\n";

    std::cout << std::left
              << std::setw(16) << "模式"
              << std::setw(18) << "吞吐(亿次/s)"
              << std::setw(12) << "相对(%)\n";
    std::cout << std::string(46, '-') << '\n';

    for (auto& r : results) {
        double pct = (r.ops / baseline) * 100.0;
        std::cout << std::left << std::fixed << std::setprecision(3)
                  << std::setw(16) << r.mode
                  << std::setw(18) << r.ops
                  << std::setw(10) << std::setprecision(1) << pct << "%\n";
    }

    std::cout << "\n── 观察要点 ──\n\n"
              << "   ▸ 顺序访问: cache line 预取完美, L1 miss 率 <2%\n"
              << "   ▸ stride=2~16: 仍在 cache line 内, 性能接近顺序\n"
              << "   ▸ stride=64: 正好一个 cache line 大小, L1 miss 率开始上升\n"
              << "   ▸ stride=256~1024: 每次访问跳多个 cache line, L1 基本全 miss\n"
              << "   ▸ 随机访问: L1 miss 率 >50%, LLC miss 率也高, 最差情况\n"
              << "\n"
              << "   核心结论: 同样的计算量, 遍历模式决定缓存行为, 进而决定性能。\n"
              << "   顺序访问是"缓存友好"的, 随机访问是"缓存不友好"的。\n";
}

// ── main ─────────────────────────────────────────────────────
int main(int argc, char** argv) {
    if (argc == 1) {
        run_full_compare();
        return 0;
    }

    std::string mode(argv[1]);

    if (mode == "seq") {
        double ops = bench_sequential();
        print_one("顺序访问", ops);
        print_perf_hint("seq");
    } else if (mode == "rand") {
        double ops = bench_random();
        print_one("随机访问", ops);
        print_perf_hint("rand");
    } else if (mode == "stride" && argc >= 3) {
        int stride = std::atoi(argv[2]);
        if (stride < 1 || stride > 16384) {
            std::cerr << "stride 需在 1~16384 之间\n";
            return 1;
        }
        double ops = bench_strided(stride);
        char label[64];
        snprintf(label, sizeof(label), "stride=%d", stride);
        print_one(label, ops);
        print_perf_hint("stride", argv[2]);
    } else {
        std::cerr << "用法: ./cache_miss [seq|rand|stride N]\n"
                  << "  无参数 → 自动跑全部模式并打印对比表\n"
                  << "  seq    → 顺序访问\n"
                  << "  rand   → 随机访问\n"
                  << "  stride N → stride=N 跨步访问\n";
        return 1;
    }

    return 0;
}
