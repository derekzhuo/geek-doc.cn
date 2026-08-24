// main.cpp —— 伪共享 (False Sharing) 检测实验
//
// 每个线程只自增"自己那一份"计数器（用线程 id 索引），逻辑上完全无共享。
// 通过对比两种内存布局，暴露伪共享对多核扩展性的拖累：
//   1. 普通 long 数组         — 相邻线程的计数器落在同一 cache line → 伪共享，性能暴跌
//   2. 每计数器 64 字节对齐    — 每个计数器独占一条 cache line       → 无乒乓，线性扩展
//
// 用 perf c2c 的 HITM% 指标精确定位伪共享：
//   HITM (Hit In The Modified) = 本核读到的 cache line 刚被另一核写过
//   HITM% 高 (>10%) → 伪共享确诊
//
// 编译: make          → -O2 -std=c++17 -pthread
//
// 用法:
//   ./false_sharing [seconds] [threads]
//     seconds  运行时长（秒），默认 10
//     threads  并发线程数，默认 2
//   例:
//     ./false_sharing            → 2 线程跑 10 秒对比
//     ./false_sharing 10 8       → 8 线程跑 10 秒对比
//     ./false_sharing 10 1       → 单线程对照（伪共享不应发生）
//
// perf 示例:
//   # 录制 c2c 事件（需 root + PEBS / AMD IBS）
//   sudo perf c2c record -a ./false_sharing 10 4
//   perf c2c report
//   perf c2c report -d

#include <iostream>
#include <thread>
#include <atomic>
#include <chrono>
#include <iomanip>
#include <vector>

// 最大支持的线程计数器容量（数组留足即可）
constexpr int MAX_THREADS = 64;

// ── 场景1: 伪共享 ────────────────────────────────────────────
// counter[i] 是普通 long，每个 8 字节，一条 64B cache line 能塞 8 个
// → 相邻线程的计数器落在同一条 line 上，产生伪共享
struct SharedState {
    volatile long counter[MAX_THREADS];
};

// ── 场景2: 无伪共享 ──────────────────────────────────────────
// 每计数器独占一条 cache line（64 字节），核间不再踩踏
struct PaddedCounter {
    volatile long value;
    char padding[64 - sizeof(long)];  // 凑满一条 cache line
};
struct PaddedState {
    PaddedCounter counter[MAX_THREADS];
};

// worker：每个线程只写自己专属下标的计数器（逻辑无共享）
// shared=true 走普通数组，false 走 padding 数组
void worker_shared(SharedState* s, int id) {
    while (!g_stop.load(std::memory_order_relaxed)) {
        s->counter[id]++;
    }
}
void worker_padded(PaddedState* s, int id) {
    while (!g_stop.load(std::memory_order_relaxed)) {
        s->counter[id].value++;
    }
}

std::atomic<bool> g_stop{false};

double bench_shared(int nthreads, int seconds) {
    SharedState data{};
    std::vector<std::thread> threads;
    threads.reserve(nthreads);
    auto t0 = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < nthreads; i++)
        threads.emplace_back(worker_shared, &data, i);
    std::this_thread::sleep_for(std::chrono::seconds(seconds));
    g_stop.store(true);
    for (auto& th : threads) th.join();
    g_stop.store(false);

    auto t1 = std::chrono::high_resolution_clock::now();
    double secs = std::chrono::duration<double>(t1 - t0).count();
    long total = 0;
    for (int i = 0; i < nthreads; i++) total += data.counter[i];
    std::cout << "  total=" << total << ", 吞吐=" << std::fixed
              << std::setprecision(1) << (total / secs / 1e6)
              << " M ops/s" << std::endl;
    return total / secs;
}

double bench_padded(int nthreads, int seconds) {
    PaddedState data{};
    std::vector<std::thread> threads;
    threads.reserve(nthreads);
    auto t0 = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < nthreads; i++)
        threads.emplace_back(worker_padded, &data, i);
    std::this_thread::sleep_for(std::chrono::seconds(seconds));
    g_stop.store(true);
    for (auto& th : threads) th.join();
    g_stop.store(false);

    auto t1 = std::chrono::high_resolution_clock::now();
    double secs = std::chrono::duration<double>(t1 - t0).count();
    long total = 0;
    for (int i = 0; i < nthreads; i++) total += data.counter[i].value;
    std::cout << "  total=" << total << ", 吞吐=" << std::fixed
              << std::setprecision(1) << (total / secs / 1e6)
              << " M ops/s" << std::endl;
    return total / secs;
}

int main(int argc, char** argv) {
    int sec = (argc >= 2) ? std::atoi(argv[1]) : 10;
    int nth = (argc >= 3) ? std::atoi(argv[2]) : 2;
    if (nth < 1) nth = 1;
    if (nth > MAX_THREADS) nth = MAX_THREADS;

    std::cout << "============================================================" << std::endl;
    std::cout << "|   伪共享（False Sharing）检测实验                        |" << std::endl;
    std::cout << "|   " << nth << " 线程各自自增各自的计数器 ( " << sec << " 秒)" << std::endl;
    std::cout << "============================================================" << std::endl;
    std::cout << std::endl;

    // 结构体大小验证（教学用）
    std::cout << "sizeof(SharedState::counter[0]) = " << sizeof(long)
              << "  (< 64, 同线程大概率同 cache line)" << std::endl;
    std::cout << "sizeof(PaddedCounter)           = " << sizeof(PaddedCounter)
              << "  (完整 cache line)" << std::endl;
    std::cout << "cache line 大小 = 64 字节 (x86-64 典型值)" << std::endl;
    std::cout << std::endl;

    std::cout << "=== 伪共享（同一 cache line）===" << std::endl;
    double s_throughput = bench_shared(nth, sec);

    std::cout << "=== 无伪共享（不同 cache line, padding 64B）===" << std::endl;
    double p_throughput = bench_padded(nth, sec);

    std::cout << std::endl;
    std::cout << "--- 对比 (" << nth << " 线程) ---" << std::endl;
    std::cout << " 伪共享：      " << std::fixed << std::setprecision(1)
              << s_throughput / 1e6 << " M ops/s" << std::endl;
    std::cout << " 无伪共享：    " << std::fixed << std::setprecision(1)
              << p_throughput / 1e6 << " M ops/s" << std::endl;
    if (s_throughput > 0) {
        double ratio = p_throughput / s_throughput;
        std::cout << " 性能差距：    " << std::fixed << std::setprecision(1)
                  << ratio << "x" << std::endl;
    }

    std::cout << std::endl;
    std::cout << "perf c2c 提示: sudo perf c2c record -a ./false_sharing "
              << sec << " " << nth << "  &&  perf c2c report" << std::endl;

    return 0;
}
