#include <atomic>
#include <chrono>
#include <cstdio>
#include <memory>
#include <thread>
#include <vector>

#include "payload.hpp"

using Clock = std::chrono::steady_clock;

constexpr long TOTAL_OPS = 4'000'000;
const int THREAD_SWEEP[] = {1, 2, 4, 6, 8, 12};

static double elapsed_ms(Clock::time_point t0, Clock::time_point t1) {
    return std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count()
           / 1000.0;
}

// 模式一：每线程独占 unique_ptr，无任何共享所有权流量。
static long long run_unique(int nth, long ops_each) {
    std::vector<std::thread> pool;
    std::vector<long long> sums(nth, 0);
    auto t0 = Clock::now();
    for (int t = 0; t < nth; ++t) {
        pool.emplace_back([&, t] {
            auto p = std::make_unique<Payload>();
            long long s = 0;
            for (long i = 0; i < ops_each; ++i) s += p->work(i);
            sums[t] = s;
        });
    }
    for (auto& th : pool) th.join();
    auto t1 = Clock::now();
    long long checksum = 0;
    for (auto v : sums) checksum += v;
    std::printf("mode=unique      threads=%2d ops=%ld elapsed_ms=%9.3f ns_per_op=%7.2f checksum=%lld\n",
                nth, ops_each * nth, elapsed_ms(t0, t1),
                elapsed_ms(t0, t1) * 1e6 / (ops_each * nth), checksum);
    return checksum;
}

// 模式二：只读裸指针共享，无所有权、无原子操作。
static long long run_raw(int nth, long ops_each) {
    auto master = std::make_unique<Payload>();
    const Payload* p = master.get();
    std::vector<std::thread> pool;
    std::vector<long long> sums(nth, 0);
    auto t0 = Clock::now();
    for (int t = 0; t < nth; ++t) {
        pool.emplace_back([&, t] {
            long long s = 0;
            for (long i = 0; i < ops_each; ++i) s += p->work(i);
            sums[t] = s;
        });
    }
    for (auto& th : pool) th.join();
    auto t1 = Clock::now();
    long long checksum = 0;
    for (auto v : sums) checksum += v;
    std::printf("mode=raw         threads=%2d ops=%ld elapsed_ms=%9.3f ns_per_op=%7.2f checksum=%lld\n",
                nth, ops_each * nth, elapsed_ms(t0, t1),
                elapsed_ms(t0, t1) * 1e6 / (ops_each * nth), checksum);
    return checksum;
}

// 模式三：shared_ptr 每线程启动时拷贝一次，任务循环内不再触碰引用计数。
static long long run_shared_ro(int nth, long ops_each) {
    auto master = std::make_shared<Payload>();
    std::vector<std::thread> pool;
    std::vector<long long> sums(nth, 0);
    auto t0 = Clock::now();
    for (int t = 0; t < nth; ++t) {
        pool.emplace_back([&, t] {
            auto local = master;  // 每线程仅一次原子增减
            long long s = 0;
            for (long i = 0; i < ops_each; ++i) s += local->work(i);
            sums[t] = s;
        });
    }
    for (auto& th : pool) th.join();
    auto t1 = Clock::now();
    long long checksum = 0;
    for (auto v : sums) checksum += v;
    std::printf("mode=shared_ro    threads=%2d ops=%ld elapsed_ms=%9.3f ns_per_op=%7.2f checksum=%lld\n",
                nth, ops_each * nth, elapsed_ms(t0, t1),
                elapsed_ms(t0, t1) * 1e6 / (ops_each * nth), checksum);
    return checksum;
}

// 模式四：每个任务都拷贝一次 shared_ptr，原子引用计数在核间高频争用。
static long long run_shared_copy(int nth, long ops_each, long* observed_peak) {
    auto master = std::make_shared<Payload>();
    std::vector<std::thread> pool;
    std::vector<long long> sums(nth, 0);
    std::atomic<long> peak{0};
    auto t0 = Clock::now();
    for (int t = 0; t < nth; ++t) {
        pool.emplace_back([&, t] {
            long long s = 0;
            for (long i = 0; i < ops_each; ++i) {
                auto local = master;  // 每任务一次原子 inc，析构时一次原子 dec
                peak.store(std::max(peak.load(), static_cast<long>(master.use_count())),
                           std::memory_order_relaxed);
                s += local->work(i);
            }
            sums[t] = s;
        });
    }
    for (auto& th : pool) th.join();
    auto t1 = Clock::now();
    *observed_peak = peak.load();
    long long checksum = 0;
    for (auto v : sums) checksum += v;
    std::printf("mode=shared_copy  threads=%2d ops=%ld elapsed_ms=%9.3f ns_per_op=%7.2f checksum=%lld use_count_peak=%ld\n",
                nth, ops_each * nth, elapsed_ms(t0, t1),
                elapsed_ms(t0, t1) * 1e6 / (ops_each * nth), checksum,
                peak.load());
    return checksum;
}

int main() {
    // 不计时预热：抹平模式顺序带来的缓存与调频冷启动差异。
    long dummy = 0;
    dummy += run_unique(1, 100000);
    dummy += run_raw(1, 100000);
    dummy += run_shared_ro(1, 100000);
    long peak = 0;
    dummy += run_shared_copy(1, 100000, &peak);
    (void)dummy;

    std::printf("# shared_ptr 引用计数争用基准 (TOTAL_OPS=%ld, work=64 轮乘加)\n", TOTAL_OPS);
    std::printf("# compiler: Apple clang, -O2 -std=c++17; 每格在线程扫档上运行\n");
    for (int nth : THREAD_SWEEP) {
        long ops_each = TOTAL_OPS / nth;
        long peak = 0;
        run_unique(nth, ops_each);
        run_raw(nth, ops_each);
        run_shared_ro(nth, ops_each);
        run_shared_copy(nth, ops_each, &peak);
        (void)peak;
    }
    return 0;
}
