// main.cpp —— 系统调用追踪实验
//
// 混合 3 种 syscall 模式，用 perf trace 观察每种系统调用的耗时和频率：
//   1. read/write   — 小文件 IO（open/read/write/close）
//   2. futex         — 锁等待（std::mutex 的底层实现）
//   3. nanosleep     — 定时睡眠
//
// perf trace 基于 perf 事件采样，性能开销远低于 strace（基于 ptrace）。
// 在 strace 会拖慢程序 10x 的场景下，perf trace 通常只拖慢 <5%。
//
// 编译: make          → -O2 -std=c++17 -lpthread
//
// 用法:
//   ./syscall_trace            → 自动运行 30 秒，三种模式依次执行
//   ./syscall_trace io         → 只跑 IO 模式
//   ./syscall_trace lock       → 只跑锁等待模式
//   ./syscall_trace sleep      → 只跑睡眠模式
//
// perf 示例:
//   # 实时看每个 syscall（-s 汇总）
//   perf trace -s ./syscall_trace
//
//   # 只看特定 syscall
//   perf trace -e '!poll,!select' ./syscall_trace
//
//   # 对比 strace 的性能开销
//   time strace -c ./syscall_trace io
//   time perf trace -s ./syscall_trace io

#include <iostream>
#include <fstream>
#include <thread>
#include <mutex>
#include <chrono>
#include <cstring>
#include <atomic>
#include <vector>

// ── 模式1: 小文件 IO ─────────────────────────────────────────
void run_io_mode(int seconds) {
    std::cout << "  [IO] 小文件 read/write, " << seconds << "s" << std::endl;
    auto end = std::chrono::steady_clock::now() + std::chrono::seconds(seconds);

    int count = 0;
    while (std::chrono::steady_clock::now() < end) {
        std::ofstream f("/tmp/perf_syscall_demo.tmp", std::ios::trunc);
        f.write("0123456789", 10);
        f.flush();
        f.close();

        std::ifstream fr("/tmp/perf_syscall_demo.tmp");
        char buf[16];
        fr.read(buf, 10);
        fr.close();
        count++;
    }
    std::cout << "  [IO] 完成 " << count << " 次 read/write 循环" << std::endl;
}

// ── 模式2: 锁等待（futex）─────────────────────────────────────
void run_lock_mode(int seconds) {
    std::cout << "  [LOCK] 4线程争用 std::mutex, " << seconds << "s" << std::endl;

    std::mutex mtx;
    int counter = 0;
    std::atomic<bool> stop{false};

    auto worker = [&]() {
        while (!stop.load(std::memory_order_relaxed)) {
            std::lock_guard<std::mutex> lk(mtx);
            counter++;
            // 短临界区：只是自增，但锁竞争会产生大量 futex 系统调用
        }
    };

    std::vector<std::thread> threads;
    for (int i = 0; i < 4; i++)
        threads.emplace_back(worker);

    std::this_thread::sleep_for(std::chrono::seconds(seconds));
    stop.store(true);

    for (auto& t : threads)
        t.join();

    std::cout << "  [LOCK] 完成 " << counter << " 次锁保护操作" << std::endl;
}

// ── 模式3: nanosleep ─────────────────────────────────────────
void run_sleep_mode(int seconds) {
    std::cout << "  [SLEEP] nanosleep 循环, " << seconds << "s" << std::endl;

    auto end = std::chrono::steady_clock::now() + std::chrono::seconds(seconds);
    int count = 0;
    while (std::chrono::steady_clock::now() < end) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        count++;
    }
    std::cout << "  [SLEEP] 完成 " << count << " 次 sleep(10ms)" << std::endl;
}

// ── main ─────────────────────────────────────────────────────
int main(int argc, char** argv) {
    int io_seconds    = 10;
    int lock_seconds  = 10;
    int sleep_seconds = 10;

    std::string mode = (argc >= 2) ? argv[1] : "all";

    std::cout << "\n╔══════════════════════════════════════════════════════════╗\n"
              << "║       系统调用追踪实验 (perf trace demo)                   ║\n"
              << "╚══════════════════════════════════════════════════════════╝\n\n";

    if (mode == "io" || mode == "all")   run_io_mode(io_seconds);
    if (mode == "lock" || mode == "all") run_lock_mode(lock_seconds);
    if (mode == "sleep" || mode == "all") run_sleep_mode(sleep_seconds);

    std::cout << "\n── perf 建议命令 ──\n\n"
              << "  # 汇总每个 syscall 的调用次数和总耗时\n"
              << "  perf trace -s ./syscall_trace\n\n"
              << "  # 只看 write/futex/nanosleep\n"
              << "  perf trace -e write -e futex -e nanosleep ./syscall_trace\n\n"
              << "  # 只跑 IO 模式，看 read/write/open/close\n"
              << "  perf trace -s ./syscall_trace io\n\n"
              << "  # 只跑锁模式，看 futex 的争用情况\n"
              << "  perf trace -s ./syscall_trace lock\n\n"
              << "  # 对比 strace 开销（strace 会明显拖慢程序）\n"
              << "  time strace -c ./syscall_trace io\n"
              << "  time perf trace -s ./syscall_trace io\n";

    return 0;
}
