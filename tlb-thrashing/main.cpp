// main.cpp —— TLB 页表翻译缓存抖动实验
//
// 经典实验:迭代次数固定 N=8192 次/趟,只增大步长 D,
// 观察 TLB 页工作集超过各级 TLB 容量时的性能断崖。
//
// 出自 Igor Ostrovsky "Gallery of Processor Cache Effects"
// 对应文档: concepts/cache/tlb.md
//
// 编译: make          → -O0 (默认,适合 perf 分析)
//       make release  → -O2 (观察优化不影响 TLB 结论)
//
// 用法:
//   ./tlb_thrashing              → 全量扫表 (D=1→1024), 自动检测拐点
//   ./tlb_thrashing 64           → 仅测 D=64, 高轮数 (适合 perf record)
//   ./tlb_thrashing 64 200000    → 仅测 D=64, 指定轮数
//
// perf 示例:
//   perf stat -e cycles,instructions,dTLB-loads,dTLB-load-misses     ./tlb_thrashing 4
//   perf stat -e cycles,instructions,dTLB-loads,dTLB-load-misses     ./tlb_thrashing 64
//   perf stat -e cycles,instructions,dTLB-loads,dTLB-load-misses,page-faults ./tlb_thrashing 512

#include <iostream>
#include <vector>
#include <chrono>
#include <iomanip>
#include <cstdlib>
#include <cstdint>
#include <sys/mman.h>  // madvise / MADV_NOHUGEPAGE

constexpr int N = (1 << 13);  // 8192 次自增 / 趟,固定不变

// 测量给定步长 D 的吞吐量(自增次数/秒)
double measure(int D, int rounds) {
    const int size = D * N;
    std::vector<int> a(size, 0);

    // 关键: 禁止 THP (透明大页) 合并本次测试的内存
    // 否则内核会把 4KB 页合并成 2MB 大页, 一个 TLB 条目覆盖 512 倍地址范围,
    // dTLB-load-misses 会几乎为 0, 整个实验退化成了 L1 dcache 测
    // (而不是 TLB thrashing 测), 结论会完全失真
    madvise(a.data(), static_cast<size_t>(size) * sizeof(int), MADV_NOHUGEPAGE);

    // 预热:走一遍以触达全部页,建立初始 TLB 状态
    for (int i = 0; i < D * N; i += D)
        a[i] = 0;

    volatile int sink = 0;

    auto t0 = std::chrono::high_resolution_clock::now();
    for (int r = 0; r < rounds; ++r) {
        for (int i = 0; i < D * N; i += D)
            a[i]++;
    }
    auto t1 = std::chrono::high_resolution_clock::now();

    // 防止编译器删除整个循环 (DCE / dead store elimination)
    // 必须读循环实际碰过的元素: 对 D>1, a[D*N-1] 从未被碰过 (不是 D 的倍数)
    sink = a[D * (N - 1)];
    (void)sink;

    double sec = std::chrono::duration<double>(t1 - t0).count();
    return static_cast<double>(rounds) * N / sec;
}

// ── 全量扫表: D=1→1024, 自动检测拐点 ──────────────────────────
void run_full_sweep() {
    int D_vals[] = {1, 2, 4, 8, 16, 32, 64, 128, 192, 256, 320, 384, 512, 768, 1024};
    constexpr int n_D = sizeof(D_vals) / sizeof(D_vals[0]);

    std::cout << "╔══════════════════════════════════════════════════════════════╗\n"
              << "║          TLB 页表翻译缓存抖动实验                            ║\n"
              << "║  每趟固定 N=" << std::setw(4) << N << " 次自增,  数组大小 = D × " << N
              << " ints = D×32KB    ║\n"
              << "║  页大小 = 4KB                                                ║\n"
              << "║  注:断崖位置因 CPU 而异,本程序自动检测实际拐点                ║\n"
              << "╚══════════════════════════════════════════════════════════════╝\n\n";

    std::cout << std::fixed << std::setprecision(3);
    std::cout << "   D  | 数组(KB) | 页工作集 | 吞吐(10⁹/s) | 相对(%)\n";
    std::cout << "------+----------+----------+-------------+--------\n";

    double baseline = 0.0;
    double prev_pct = 100.0;  // 上一个 D 的相对吞吐,用于找"跌幅 >50%"的真正断崖

    int l1_cliff_idx = -1, l2_cliff_idx = -1;

    for (int k = 0; k < n_D; ++k) {
        int D     = D_vals[k];
        int pages = 8 * D;

        int rounds = 5000;
        if (D >= 256) rounds = 2000;
        if (D >= 512) rounds = 1000;
        if (D >= 768) rounds = 500;

        double ops = measure(D, rounds);

        if (k == 0) baseline = ops;
        double pct = (ops / baseline) * 100.0;

        if (l1_cliff_idx < 0 && pct < 70.0) l1_cliff_idx = k;
        if (l1_cliff_idx >= 0 && l2_cliff_idx < 0
            && k > l1_cliff_idx && pct < 0.5 * prev_pct) {
            l2_cliff_idx = k;
        }
        prev_pct = pct;

        std::cout << std::right
                  << std::setw(4) << D     << "  │ "
                  << std::setw(8) << (D * N * 4 / 1024) << " │ "
                  << std::setw(8) << pages << " │ "
                  << std::setw(11) << (ops / 1e9) << " │ "
                  << std::setw(5) << static_cast<int>(pct) << "%";

        if (k == l1_cliff_idx)         std::cout << "  ← L1 拐点";
        else if (k == l2_cliff_idx)    std::cout << "  ← L2 拐点 (thrashing)";
        std::cout << '\n';
    }

    std::cout << "\n── 观察要点 (对照 concepts/cache/tlb.md §三.3):\n\n";

    if (l1_cliff_idx > 0) {
        int d1 = D_vals[l1_cliff_idx];
        int prev_d1 = (l1_cliff_idx > 0) ? D_vals[l1_cliff_idx - 1] : 1;
        std::cout << "   ▸ L1 dTLB 拐点: D = " << d1
                  << "  (8D = " << (8 * d1) << " 页)"
                  << "  →  L1 dTLB 容量 ≤ " << (8 * d1)
                  << " 条目  (介于 " << (8 * prev_d1) << " ~ " << (8 * d1) << " 之间)\n";
    }
    if (l2_cliff_idx > 0) {
        int d2 = D_vals[l2_cliff_idx];
        int prev_d2 = (l2_cliff_idx > 0) ? D_vals[l2_cliff_idx - 1] : 1;
        std::cout << "   ▸ L2 STLB 拐点: D = " << d2
                  << "  (8D = " << (8 * d2) << " 页)"
                  << "  →  L2 STLB 容量 ≤ " << (8 * d2)
                  << " 条目  (介于 " << (8 * prev_d2) << " ~ " << (8 * d2) << " 之间)\n";
    }
    if (l1_cliff_idx < 0 || l2_cliff_idx < 0) {
        std::cout << "   (L1/L2 拐点未明显分开 —— 可能这台机器两级 TLB 容量接近,\n"
                  << "    或 L2 拐点在本实验最大步长 (D=1024) 之后)\n";
    }

    std::cout << "\n"
              << "   平台区 (D 小):  8D ≤ L1 dTLB, 翻译命中, ≈0 开销\n"
              << "   阶梯区 (D 中):  8D 越过 L1 但 ≤ L2 STLB, L1 miss 但 STLB 兜住\n"
              << "   断崖区 (D 大):  8D > L2 STLB, 每趟回来翻译被挤光,\n"
              << "                  每次自增前挂一趟几十~上百拍 page walk\n"
              << "\n"
              << "   自增次数一样 (8192次/趟), 翻译过路费从 ≈0 变成 ~100拍/次,\n"
              << "   吞吐下降不是数据缓存的锅, 真凶是 TLB。\n"
              << "\n"
              << "   附加现象: D=2~8 吞吐常 > D=1, 因 D=1 时所有自增挤同一条\n"
              << "   cache line → 流水线串行; D=2~8 散到多条 line → 触发 MLP。\n"
              << "\n"
              << "   注: 不同 CPU 的 TLB 容量不同 (Intel/AMD/代次), 断崖的\n"
              << "   绝对 D 值因机器而异, 原理都是 8D > TLB容量就崩。\n"
              << "   查本机实际值:\n"
              << "       Linux:  $ cpuid | grep -i 'TLB'\n"
              << "       macOS:  $ sysctl machdep.cpu\n";
}

// ── 单步长模式: 只测一个 D, 高轮数适合 perf ─────────────────────
void run_single_d(int D, int rounds) {
    int64_t arrbytes = static_cast<int64_t>(D) * N * 4;
    int pages    = 8 * D;

    std::cout << std::fixed << std::setprecision(3);
    std::cout << "── TLB 单步长模式 (perf 友好) ──\n\n"
              << "   D        = " << D << "\n"
              << "   页工作集  = " << pages << " 页  (8D = D×" << N << "×4 / 4096)\n"
              << "   数组大小   = " << arrbytes << " B  (" << (arrbytes / 1024.)
              << " KB, " << (arrbytes / (1024.*1024.)) << " MB)\n"
              << "   趟数       = " << rounds << "\n"
              << "   总自增次数 = " << (long long)rounds * N << "\n\n";

    // 预热一次
    double ops = measure(D, rounds);

    std::cout << "   吞吐 = " << (ops / 1e9) << " ×10⁹ 自增/s\n"
              << "   耗时 ≈ " << (rounds * N / ops)
              << " s  (足够 perf 采样)\n\n"
              << "── perf 建议命令 ──\n\n"
              << "  # 对比 TLB miss 率\n"
              << "  perf stat -e cycles,instructions,\\"
              << "dTLB-loads,dTLB-load-misses \\\n"
              << "      ./tlb_thrashing " << D << "\n\n"
              << "  # 采样 callchain (看哪些代码在 walk)\n"
              << "  perf record -e dTLB-load-misses -g \\\n"
              << "      ./tlb_thrashing " << D << "\n"
              << "  perf report --stdio\n\n"
              << "  # 对比不同 D 的 TLB miss 变化\n"
              << "  for d in 4 8 16 32 64 128 256 512; do\n"
              << "    echo \"=== D=\\$d ===\"\n"
              << "    perf stat -e dTLB-loads,dTLB-load-misses ./tlb_thrashing \\$d 2>&1 | grep dTLB\n"
              << "  done\n";
    (void)ops;  // 已在上面打印
}

// ── main ─────────────────────────────────────────────────────────
int main(int argc, char** argv) {
    // 无参数 → 全量扫表
    if (argc == 1) {
        run_full_sweep();
        return 0;
    }

    // 单步长模式
    int D = std::atoi(argv[1]);
    if (D < 1 || D > 65536) {
        std::cerr << "用法: ./tlb_thrashing [D] [rounds]\n"
                  << "  D: 步长 (1~65536)\n"
                  << "  rounds: 趟数 (默认 100000, 适合 perf)\n"
                  << "  无参数 → 全量扫表 D=1→1024\n";
        return 1;
    }

    int rounds = 100000;
    if (argc >= 3) {
        rounds = std::atoi(argv[2]);
        if (rounds < 100) rounds = 100;
    }

    run_single_d(D, rounds);
    return 0;
}
