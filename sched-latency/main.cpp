// main.cpp —— 调度延迟诊断实验
//
// 混合 3 种调度模式，用 perf sched record/latency/timehist/map 分析：
//   1. CPU 密集型      — 一直跑，几乎不切换，runtime 高 wait 低
//   2. IO 等待型       — 频繁 usleep，大量睡眠/唤醒，wait 高
//   3. 多线程竞争型     — N线程 > CPU核数，频繁抢占，调度延迟最长
//
// 编译: make          → -O2 -std=c++17 -lpthread
//
// 用法:
//   ./sched_latency            → 全部三种模式各跑 10 秒
//   ./sched_latency cpu        → 只跑 CPU 模式
//   ./sched_latency io         → 只跑 IO 模式
//   ./sched_latency compete    → 只跑竞争模式
//   ./sched_latency cpu 20     → 指定秒数
//
// perf 示例:
//   # 录制调度事件
//   sudo perf sched record -a ./sched_latency
//
//   # 分析调度延迟
//   perf sched latency
//
//   # 时间线可视化
//   perf sched timehist -V
//
//   # 汇总统计
//   perf sched timehist -s
//
//   # ASCII 调度图
//   perf sched map

#include <iostream>
#include <thread>
#include <atomic>
#include <chrono>
#include <vector>
#include <cstring>
#include <unistd.h>

// ── 模式1: CPU 密集型 ────────────────────────────────────────
void run_cpu_mode(int seconds) {
    std::cout << "  [CPU] 纯计算, " << seconds << "s" << std::endl;

    std::atomic<bool> stop{false};
    volatile long sink = 0;

    auto worker = [&]() {
        while (!stop.load(std::memory_order_relaxed)) {
            for (int i = 0; i < 100000; i++)
                sink += i;
        }
    };

    // 2 个 CPU 密集线程（通常 < 核数，不触发频繁抢占）
    std::thread t1(worker), t2(worker);
    std::this_thread::sleep_for(std::chrono::seconds(seconds));
    stop.store(true);
    t1.join(); t2.join();
    (void)sink;

    std::cout << "  [CPU] 完成 (几乎全是 runtime, wait 接近 0)" << std::endl;
}

// ── 模式2: IO 等待型 ────────────────────────────────────────
void run_io_mode(int seconds) {
    std::cout << "  [IO] 频繁 sleep(1ms), " << seconds << "s" << std::endl;

    std::atomic<bool> stop{false};
    int count = 0;

    auto worker = [&]() {
        while (!stop.load(std::memory_order_relaxed)) {
            usleep(1000);  // 1ms 睡眠 → 频繁调度
            count++;
        }
    };

    // 4 个线程频繁睡眠/唤醒
    std::vector<std::thread> threads;
    for (int i = 0; i < 4; i++)
        threads.emplace_back(worker);

    std::this_thread::sleep_for(std::chrono::seconds(seconds));
    stop.store(true);
    for (auto& t : threads) t.join();

    std::cout << "  [IO] 完成 " << count << " 次 sleep/wakeup"
              << " (wait 应该很高)" << std::endl;
}

// ── 模式3: 多线程竞争型 ──────────────────────────────────────
void run_compete_mode(int seconds) {
    int ncpu = sysconf(_SC_NPROCESSORS_ONLN);
    int nthreads = ncpu * 4;  // 4 倍核数的线程 → 必定频繁抢占

    std::cout << "  [COMPETE] " << nthreads << " 线程 争 " << ncpu
              << " 核, " << seconds << "s" << std::endl;

    std::atomic<bool> stop{false};
    std::atomic<long> ops{0};

    auto worker = [&]() {
        while (!stop.load(std::memory_order_relaxed)) {
            for (int i = 0; i < 10000; i++) {
                volatile int x = i * i;
                (void)x;
            }
            ops.fetch_add(1, std::memory_order_relaxed);
        }
    };

    std::vector<std::thread> threads;
    for (int i = 0; i < nthreads; i++)
        threads.emplace_back(worker);

    std::this_thread::sleep_for(std::chrono::seconds(seconds));
    stop.store(true);
    for (auto& t : threads) t.join();

    std::cout << "  [COMPETE] 完成 " << ops.load() << " 个 work unit"
              << " (调度延迟应该最高)" << std::endl;
}

// ── main ─────────────────────────────────────────────────────
int main(int argc, char** argv) {
    std::string mode = (argc >= 2) ? argv[1] : "all";
    int sec = (argc >= 3) ? std::atoi(argv[2]) : 10;
    if (sec < 2) sec = 2;

    std::cout << "\n╔══════════════════════════════════════════════════════════╗\n"
              << "║       调度延迟诊断实验 (perf sched demo)                   ║\n"
              << "╚══════════════════════════════════════════════════════════╝\n\n";

    std::cout << "  核数: " << sysconf(_SC_NPROCESSORS_ONLN) << '\n'
              << "  每组 " << sec << " 秒\n\n";

    if (mode == "cpu" || mode == "all")     run_cpu_mode(sec);
    if (mode == "io" || mode == "all")      run_io_mode(sec);
    if (mode == "compete" || mode == "all") run_compete_mode(sec);

    std::cout << "\n── perf 建议命令 ──\n\n"
              << "  # 第一步: 录制调度事件 (需 root)\n"
              << "  sudo perf sched record -a ./sched_latency\n\n"
              << "  # 第二步: 查看每线程的调度延迟\n"
              << "  perf sched latency\n\n"
              << "  # 第三步: 时间线可视化 (看 CPU 占用分布)\n"
              << "  perf sched timehist -V\n\n"
              << "  # 第四步: 汇总统计 (按线程) \n"
              << "  perf sched timehist -s\n\n"
              << "  # 第五步: ASCII 调度图\n"
              << "  perf sched map\n\n"
              << "── 预期观察 ──\n\n"
              << "   ▸ CPU 模式: Runtime 高, Wait 低, 切换次数少\n"
              << "   ▸ IO 模式:   Wait 高, 切换次数极多 (usleep 每 ms 切一次)\n"
              << "   ▸ 竞争模式:  Avg Wait 最高, 线程数 >> 核数导致频繁抢占\n\n"
              << "  提示: 不同的 sched:* tracepoint 提供不同维度\n"
              << "    sched:sched_stat_runtime → 累计运行时间\n"
              << "    sched:sched_stat_wait    → 就绪队列等待时间\n"
              << "    sched:sched_switch       → 每次切换的 prev/next task\n"
              << "    sched:sched_wakeup       → 谁唤醒了谁\n";

    return 0;
}
