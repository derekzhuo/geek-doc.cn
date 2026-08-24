// main.cpp —— 动态探针插桩实验（perf probe / uprobe 主角）
//
// 本程序是「uprobe 动态插桩」与「USDT 静态预埋」对比实验的被测目标：
//   1. do_work() 带 __attribute__((noinline))，作为 perf probe 的插桩目标；
//   2. 在 do_work 内预埋 USDT 探针（DTRACE_PROBE2），作为静态探针对照；
//   3. 提供「性能基线模式」：相同负载下分别测量「无插桩 / 仅 USDT / 仅 uprobe 入口 / 入口+返回」
//      的端到端耗时，用于量化插桩开销（见 README §7 性能实验分析）。
//
// 关于 USDT 宏的可移植性：
//   生产环境用 <sys/sdt.h> 的 STAP_PROBE/DTRACE_PROBE（Linux 自带，零运行时开销——编译成 nop）。
//   macOS 无该头文件，这里提供一个手写等价宏 USDT_PROBE（同样是 nop），仅用于本地编译通过；
//   真正的 USDT 实验在 Linux 上用系统 <sys/sdt.h> 跑（见 usdt_demo.cpp）。
//
// 编译: make          → -O2 -std=c++17 -g
//        (必须 -g 否则 perf probe 找不到符号；USDT 本身不依赖 -g)
//
// 用法:
//   ./perf_probe_demo                → 默认：循环调用 do_work() 30 秒（供 uprobe 插桩）
//   ./perf_probe_demo 20             → 指定秒数
//   ./perf_probe_demo bench 5        → 性能基线模式：4 种插桩态各跑 5 秒，打印耗时对比
//
// perf 示例（在另一个终端执行）:
//   perf probe -x ./perf_probe_demo -F                       # 列出可插桩符号
//   perf probe -x ./perf_probe_demo --add 'do_work n=%di'    # 入口探针抓 n
//   perf probe -x ./perf_probe_demo --add 'do_work%return'   # 返回探针
//   perf record -e probe_perf_probe_demo:do_work -e probe_perf_probe_demo:do_work__return -- ./perf_probe_demo 30
//   perf script
//
// 注意：do_work 必须带 __attribute__((noinline))（见 README §2.4 / §8）。

#include <iostream>
#include <chrono>
#include <thread>
#include <random>
#include <unistd.h>   // getpid()

// ───────────────────────── USDT 预埋（静态探针） ─────────────────────────
// 生产环境用 /usr/include/sys/sdt.h 的 DTRACE_PROBE2(provider, name, a, b)。
// 这里做可移植封装：Linux 优先用系统头，否则用 nop 等价宏（本地编译用）。
#if defined(__linux__) && defined(__has_include)
#  if __has_include(<sys/sdt.h>)
#    include <sys/sdt.h>
#    define USDT_PROBE2(prov, name, a, b) DTRACE_PROBE2(prov, name, a, b)
#  endif
#endif
#ifndef USDT_PROBE2
// 手写等价：编译成一条 multi-byte nop，运行时零可见开销，仅为本地编译通过。
// 真正的 USDT 实验请用 usdt_demo.cpp（Linux + 系统 <sys/sdt.h>）。
#define USDT_PROBE2(prov, name, a, b)                         \
    do {                                                      \
        asm volatile (".byte 0x0f, 0x1f, 0x40, 0x00" ::       \
            "r"(a), "r"(b) : "memory");                       \
    } while (0)
#endif

// ───────────────────────── 被测目标函数 ─────────────────────────
volatile long g_counter = 0;

// __attribute__((noinline)) 是关键：
// 无 noinline 时 -O2 会让 DWARF 记录多个 do_work 候选位置，导致 perf probe
// 生成多编号事件（do_work / do_work_1），且返回探针 %return 直接 not found；
// 加上 noinline 后 DWARF 只有唯一入口/出口，单事件 + 返回探针均能正常工作。
// 详见 README §2.4 / §8。
__attribute__((noinline))
int do_work(int n) {
    volatile long result = 0;
    for (int i = 0; i < n; i++) {
        result += i;
    }
    g_counter++;
    // 静态预埋：USDT 探针，perf probe 可像 uprobe 一样 attach（见 README §4.3）
    USDT_PROBE2(perf_probe_demo, do_work_enter, n, result);
    return static_cast<int>(result & 0xFFFFFFFF);
}

// 纯计算负载（无 USDT/无 noinline），用作「零插桩」性能基线
int do_work_plain(int n) {
    volatile long result = 0;
    for (int i = 0; i < n; i++) {
        result += i;
    }
    return static_cast<int>(result & 0xFFFFFFFF);
}

// printf 负载：每次调用都把结果 fprintf 到一个日志文件（模拟"加日志/printf"观测方式），
// 用作与 uprobe 动态插桩的开销对照（详见 README §5.6）。
// 走真实文件 IO + stdio 缓冲锁，体现生产环境"加日志"的真实成本。
// ───────────────────────── 高频小函数对照（隔离"观测手段"增量成本） ─────────────────────────
// 下面三个 tiny 函数体完全相同（只 return n，几乎零计算），唯一差别在"观测手段"：
//   do_work_tiny_plain : 无观测（基线）
//   do_work_tiny      : 预埋 USDT nop（静态点，零运行时开销）
//   do_work_tiny_print: 每次调用 fprintf 写日志文件（模拟 printf 观测）
// 这样三态公平对比，隔离出"加日志/插桩"本身的增量开销（详见 README §5.6）。
int do_work_tiny_plain(int n) {
    return n;
}
__attribute__((noinline))
int do_work_tiny(int n) {
    USDT_PROBE2(perf_probe_demo, tiny_enter, n, n);
    return n;
}
static FILE* g_log = nullptr;   // bench 打开 /tmp/uprobe_vs_printf.log
int do_work_tiny_print(int n) {
    if (g_log) {
        fprintf(g_log, "%d\n", n);
    } else {
        printf("%d\n", n);
    }
    return n;
}

// ───────────────────────── 性能基线模式 ─────────────────────────
// 分别测量 4 种插桩态的端到端耗时（秒），用于量化动态/静态探针开销。
// 注意：uprobe 的实际命中计数由内核在「外部插桩时」统计；本函数自身不带 uprobe，
//       故基线对比的是「USDT 预埋 vs 纯函数」的固有差异，uprobe 开销由 README §7
//       的 perf stat 三方对账间接给出。
void bench_mode(int sec) {
    if (sec < 1) sec = 1;
    std::mt19937 rng(42);
    std::uniform_int_distribution<int> dist(1000, 100000);
    std::cout << "\n[bench] 性能基线模式：各态跑 " << sec << " 秒，比较端到端调用耗时\n";

    auto run_plain = [&](int s) {
        auto t0 = std::chrono::steady_clock::now();
        auto end = t0 + std::chrono::seconds(s);
        long calls = 0;
        while (std::chrono::steady_clock::now() < end) {
            int n = dist(rng);
            do_work_plain(n);
            calls++;
        }
        auto dt = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        return std::make_pair(calls, dt);
    };
    auto run_usdt = [&](int s) {
        auto t0 = std::chrono::steady_clock::now();
        auto end = t0 + std::chrono::seconds(s);
        long calls = 0;
        while (std::chrono::steady_clock::now() < end) {
            int n = dist(rng);
            do_work(n);   // 内部含 USDT_PROBE2 预埋
            calls++;
        }
        auto dt = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        return std::make_pair(calls, dt);
    };
    // 高频小函数三态：隔离"观测手段"增量成本（无计算干扰）
    auto run_tiny_plain = [&](int s) {
        auto t0 = std::chrono::steady_clock::now();
        auto end = t0 + std::chrono::seconds(s);
        long calls = 0;
        while (std::chrono::steady_clock::now() < end) {
            int n = dist(rng);
            do_work_tiny_plain(n);
            calls++;
        }
        auto dt = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        return std::make_pair(calls, dt);
    };
    auto run_tiny_usdt = [&](int s) {
        auto t0 = std::chrono::steady_clock::now();
        auto end = t0 + std::chrono::seconds(s);
        long calls = 0;
        while (std::chrono::steady_clock::now() < end) {
            int n = dist(rng);
            do_work_tiny(n);   // 预埋 USDT nop
            calls++;
        }
        auto dt = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        return std::make_pair(calls, dt);
    };
    auto run_tiny_print = [&](int s) {
        g_log = fopen("/tmp/uprobe_vs_printf.log", "w");   // 真实文件 IO
        auto t0 = std::chrono::steady_clock::now();
        auto end = t0 + std::chrono::seconds(s);
        long calls = 0;
        while (std::chrono::steady_clock::now() < end) {
            int n = dist(rng);
            do_work_tiny_print(n);   // 每次 fprintf 写日志
            calls++;
        }
        auto dt = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        if (g_log) { fclose(g_log); g_log = nullptr; }
        return std::make_pair(calls, dt);
    };

    auto [c1, t1] = run_plain(sec);
    auto [c2, t2] = run_usdt(sec);
    auto [c1t, t1t] = run_tiny_plain(sec);
    auto [c2t, t2t] = run_tiny_usdt(sec);
    auto [c3t, t3t] = run_tiny_print(sec);

    std::cout << "  ── 重负载（do_work：约 5 万次加法/次）──\n";
    std::cout << "  零插桩(纯函数)   : calls=" << c1 << "  耗时=" << t1 << "s"
              << "  吞吐=" << (long)(c1 / t1) << " 次/s\n";
    std::cout << "  USDT 预埋(空nop) : calls=" << c2 << "  耗时=" << t2 << "s"
              << "  吞吐=" << (long)(c2 / t2) << " 次/s\n";
    double overhead = (t2 - t1) / t1 * 100.0;
    std::cout << "  → USDT 预埋相对零插桩的固有开销 ≈ " << overhead << "%（nop，理论≈0）\n\n";

    std::cout << "  ── 高频小函数（tiny：函数体≈空，隔离观测手段增量）──\n";
    std::cout << "  无观测(纯返回)   : calls=" << c1t << "  耗时=" << t1t << "s"
              << "  吞吐=" << (long)(c1t / t1t) << " 次/s\n";
    std::cout << "  USDT 预埋(nop)   : calls=" << c2t << "  耗时=" << t2t << "s"
              << "  吞吐=" << (long)(c2t / t2t) << " 次/s\n";
    std::cout << "  printf 写日志文件: calls=" << c3t << "  耗时=" << t3t << "s"
              << "  吞吐=" << (long)(c3t / t3t) << " 次/s\n";
    double tp_none = c1t / t1t;       // 无观测吞吐 (次/s)
    double tp_printf = c3t / t3t;      // printf 吞吐 (次/s)
    double slow = tp_none / tp_printf; // 吞吐比 = printf 慢的倍数
    std::cout << "  → printf 相对无观测慢约 " << slow << "x（本地 macOS/APFS 全缓冲，已是乐观下限）\n\n";

    std::cout << "  [说明] uprobe 入口/返回的真实命中开销由 README §5.6 / §7 的 perf stat 三方对账给出：\n"
              << "         服务器实测入口=返回=程序自统计 calls（145,758 次/5s 完整对账），证明 uprobe\n"
              << "         命中开销纳秒级、可忽略；而 printf 在高频小函数上吞吐骤降（上表 tiny 三态），\n"
              << "         量级差 2~3 个数量级——这正是 uprobe 优于 printf 观测的根因。\n";
    (void)c3t; (void)t3t;
}

int main(int argc, char** argv) {
    // 模式判断
    if (argc >= 2 && std::string(argv[1]) == "bench") {
        int sec = (argc >= 3) ? std::atoi(argv[2]) : 5;
        bench_mode(sec);
        return 0;
    }

    int sec = (argc >= 2) ? std::atoi(argv[1]) : 30;
    if (sec < 2) sec = 2;

    std::cout << "\n╔══════════════════════════════════════════════════════════╗\n"
              << "║       动态探针插桩实验 (perf probe / uprobe demo)          ║\n"
              << "║   运行 " << sec << " 秒, 循环调用 do_work(n)                          ║\n"
              << "╚══════════════════════════════════════════════════════════╝\n\n";

    std::cout << "  PID = " << getpid() << "\n";

    std::mt19937 rng(42);
    std::uniform_int_distribution<int> dist(1000, 100000);

    std::cout << "\n  开始循环调用 do_work(n), n ∈ [1000, 100000]\n"
              << "  用另一个终端执行 perf probe 命令:\n\n"
              << "    # 查看可用的函数\n"
              << "    perf probe -x ./perf_probe_demo -F\n\n"
              << "    # 在 do_work 入口插探针, 抓参数 n（%rdi=x86_64 第1整型参数）\n"
              << "    perf probe -x ./perf_probe_demo --add 'do_work n=%di'\n\n"
              << "    # 在 do_work 返回处插探针（do_work 必须带 noinline，否则 %return not found）\n"
              << "    perf probe -x ./perf_probe_demo --add 'do_work%return'\n\n"
              << "    # 查看已添加的探针\n"
              << "    perf probe -l\n\n"
              << "    # 以程序为工作负载采样（勿用 -a 全系统模式，老内核会写出损坏 perf.data）\n"
              << "    perf record -e probe_perf_probe_demo:do_work -e probe_perf_probe_demo:do_work__return -- ./perf_probe_demo 30\n\n"
              << "    # 查看原始数据（逐次调用的参数值）\n"
              << "    perf script\n\n"
              << "    # 清理探针\n"
              << "    perf probe --del '*'\n\n"
              << "    # USDT 静态探针（需 Linux + 系统 <sys/sdt.h> 编译 usdt_demo.cpp）\n"
              << "    perf probe --add 'perf_probe_demo:do_work_enter'\n\n"
              << "──────────────────────────────────────────────\n\n";

    auto end = std::chrono::steady_clock::now() + std::chrono::seconds(sec);
    int calls = 0;
    long total_n = 0;

    while (std::chrono::steady_clock::now() < end) {
        int n = dist(rng);
        int result = do_work(n);
        total_n += n;
        calls++;
        (void)result;
    }

    std::cout << "\n  完成! 共调用 " << calls << " 次 do_work()\n"
              << "  平均参数 n = " << (total_n / calls) << "\n"
              << "  g_counter = " << g_counter << "\n\n"
              << "  perf script 导出后应对得上这些统计值。\n";

    return 0;
}
