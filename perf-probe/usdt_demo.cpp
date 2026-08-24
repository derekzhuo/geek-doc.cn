// usdt_demo.cpp —— USDT 静态定义跟踪点（User Statically Defined Tracing）对照实验
//
// 与 main.cpp 的区别：
//   main.cpp 的 do_work 用 perf probe 在「运行时」动态插桩（uprobe）；
//   本程序在源码里「预埋」USDT 探针（静态），编译进二进制，运行时用
//   `perf probe --add 'usdt_demo:work_enter'` 即可 attach，无需 -g、无需 DWARF。
//
// USDT 的本质（见 README §1.2b / §4.3）：
//   源码里写 DTRACE_PROBE2(provider, name, a, b)，编译后变成一条「空操作(nop)」指令
//   + 一段 ELF note（.note.stapsdt）记录参数位置。运行时开销≈0，直到有人 attach。
//
// 依赖：Linux 系统的 <sys/sdt.h>（systemtap-sdt-dev 包，通常自带）。
//       本文件仅作 USDT 对照，macOS 上不编译（Makefile 仅在 Linux 构建）。
//
// 编译（Linux）: g++ -O2 -std=c++17 usdt_demo.cpp -o usdt_demo
//
// 用法:
//   ./usdt_demo            → 循环调用 work() 30 秒（内部触发 USDT 预埋点）
//   ./usdt_demo 20         → 指定秒数
//
// 观测（另一个终端）:
//   # 列出二进制里的 USDT 点
//   readelf -n ./usdt_demo | grep -A4 stapsdt
//   # 或
//   perf probe -x ./usdt_demo -L work
//
//   # attach USDT 探针（静态点，无需 -g）
//   perf probe -x ./usdt_demo --add 'usdt_demo:work_enter'
//   perf probe -l
//
//   # 采样 + 导出
//   perf record -e probe_usdt_demo:work_enter -o perf_usdt.data -- ./usdt_demo 30
//   perf script -i perf_usdt.data
//
//   # 清理
//   perf probe --del '*'

#include <iostream>
#include <chrono>
#include <random>
#include <unistd.h>
#ifdef __linux__
#  include <sys/sdt.h>   // DTRACE_PROBE2：编译成 nop + ELF note
#endif

volatile long g_counter = 0;

// 被预埋 USDT 点的函数（无需 noinline——USDT 是源码固定点，不依赖 DWARF）
int work(int n) {
    volatile long result = 0;
    for (int i = 0; i < n; i++) {
        result += i;
    }
    g_counter++;
#ifdef __linux__
    // 静态预埋：provider=usdt_demo, name=work_enter, 参数 n 与 result
    DTRACE_PROBE2(usdt_demo, work_enter, n, result);
#endif
    return static_cast<int>(result & 0xFFFFFFFF);
}

int main(int argc, char** argv) {
    int sec = (argc >= 2) ? std::atoi(argv[1]) : 30;
    if (sec < 2) sec = 2;

    std::cout << "\n[USDT demo] 运行 " << sec << " 秒, 循环调用 work(n)（内部含 USDT 静态预埋点）\n";
    std::cout << "  PID = " << getpid() << "\n";
    std::cout << "  另一个终端执行: perf probe --add 'usdt_demo:work_enter'\n\n";

    std::mt19937 rng(42);
    std::uniform_int_distribution<int> dist(1000, 100000);

    auto end = std::chrono::steady_clock::now() + std::chrono::seconds(sec);
    int calls = 0;
    long total_n = 0;

    while (std::chrono::steady_clock::now() < end) {
        int n = dist(rng);
        int result = work(n);
        total_n += n;
        calls++;
        (void)result;
    }

    std::cout << "\n  完成! 共调用 " << calls << " 次 work()\n"
              << "  平均参数 n = " << (total_n / calls) << "\n"
              << "  用 perf probe --add 'usdt_demo:work_enter' 可 attach 这个静态点。\n";

    return 0;
}
