// 自旋锁 / std::mutex（futex 休眠）/ glibc 自适应锁在不同临界区长度下的对照基准。
//
// 三种锁：
//   spin      —— atomic_flag 纯自旋，抢不到就在用户态忙等；
//   mutex     —— std::mutex，glibc 内部走 futex，竞争失败进内核休眠；
//   adaptive  —— pthread PTHREAD_MUTEX_ADAPTIVE_NP，先有限次自旋再休眠（Linux/glibc 专属）。
//
// 临界区五级：w1/w30/w300/w3000/w30000 是对共享变量的受控运算循环，
// sleep100us 在临界区内 sleep 100 微秒。启动时先单线程无锁校准每级的实际耗时，
// 文章引用校准值而不是名义值。
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <thread>
#include <vector>

#include <pthread.h>
#include <time.h>
#include <unistd.h>

namespace {

struct SpinLock {
    std::atomic_flag flag = ATOMIC_FLAG_INIT;
    void lock() {
        while (flag.test_and_set(std::memory_order_acquire)) {
        }
    }
    void unlock() { flag.clear(std::memory_order_release); }
};

struct StdMutex {
    std::mutex m;
    void lock() { m.lock(); }
    void unlock() { m.unlock(); }
};

struct AdaptiveMutex {
    pthread_mutex_t m;
    AdaptiveMutex() {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ADAPTIVE_NP);
        pthread_mutex_init(&m, &attr);
        pthread_mutexattr_destroy(&attr);
    }
    ~AdaptiveMutex() { pthread_mutex_destroy(&m); }
    void lock() { pthread_mutex_lock(&m); }
    void unlock() { pthread_mutex_unlock(&m); }
};

// 临界区工作负载等级：名字 -> 共享运算循环次数；sleep 级单独处理。
struct CsLevel {
    const char *name;
    int work_iters;
    bool sleep;
    long iters_per_thread;
};

constexpr CsLevel kLevels[] = {
    {"w1",      1,     false, 400000},
    {"w30",     30,    false, 100000},
    {"w300",    300,   false, 40000},
    {"w3000",   3000,  false, 10000},
    {"w30000",  30000, false, 2000},
    {"sleep100us", 0,  true,  1000},
};

constexpr int kThreadCounts[] = {1, 2, 4, 8};

// 防止编译器把临界区运算优化掉的共享汇点。
volatile uint64_t g_sink = 0;

inline void critical_work(int work_iters, bool do_sleep) {
    uint64_t acc = g_sink;
    for (int i = 1; i <= work_iters; ++i) {
        acc = acc * 1103515245u + 12345u + static_cast<uint64_t>(i);
    }
    g_sink = acc;
    if (do_sleep) {
        timespec ts{0, 100 * 1000};  // 100 微秒
        nanosleep(&ts, nullptr);
    }
}

template <typename Lock>
double run_config(Lock &lock, const CsLevel &lv, int threads, uint64_t &total_ops) {
    total_ops = static_cast<uint64_t>(lv.iters_per_thread) * threads;
    auto worker = [&](int) {
        for (long i = 0; i < lv.iters_per_thread; ++i) {
            lock.lock();
            critical_work(lv.work_iters, lv.sleep);
            lock.unlock();
        }
    };
    std::vector<std::thread> pool;
    pool.reserve(threads);
    auto t0 = std::chrono::steady_clock::now();
    for (int t = 0; t < threads; ++t) pool.emplace_back(worker, t);
    for (auto &th : pool) th.join();
    auto t1 = std::chrono::steady_clock::now();
    return std::chrono::duration<double, std::nano>(t1 - t0).count() /
           static_cast<double>(total_ops);
}

// 单线程无锁校准：每级临界区本身的平均耗时（纳秒）。
double calibrate(const CsLevel &lv) {
    constexpr int kSamples = 2000;
    auto t0 = std::chrono::steady_clock::now();
    for (int i = 0; i < kSamples; ++i) critical_work(lv.work_iters, lv.sleep);
    auto t1 = std::chrono::steady_clock::now();
    return std::chrono::duration<double, std::nano>(t1 - t0).count() / kSamples;
}

template <typename Lock>
void sweep(const char *lock_name, Lock &lock) {
    const char *filter_lock = std::getenv("FILTER_LOCK");
    const char *filter_cs = std::getenv("FILTER_CS");
    const int filter_threads = std::getenv("FILTER_THREADS")
                                    ? std::atoi(std::getenv("FILTER_THREADS"))
                                    : 0;
    if (filter_lock && std::strcmp(filter_lock, lock_name) != 0) return;
    for (const CsLevel &lv : kLevels) {
        if (filter_cs && std::strcmp(filter_cs, lv.name) != 0) continue;
        for (int threads : kThreadCounts) {
            if (filter_threads && threads != filter_threads) continue;
            uint64_t ops = 0;
            double ns_op = run_config(lock, lv, threads, ops);
            double mops = static_cast<double>(ops) /
                          (ns_op * static_cast<double>(ops) / 1e9) / 1e6;
            std::printf("RESULT lock=%-8s threads=%d cs=%-11s ns_op=%10.2f throughput_mops=%8.3f ops=%llu\n",
                        lock_name, threads, lv.name, ns_op, mops,
                        static_cast<unsigned long long>(ops));
        }
    }
}

}  // namespace

int main() {
    std::printf("# 三锁临界区长度扫档基准\n");
    std::printf("# 校准（单线程无锁，临界区平均耗时 ns）：\n");
    for (const CsLevel &lv : kLevels) {
        std::printf("# CALIB cs=%-11s mean_ns=%10.2f\n", lv.name, calibrate(lv));
    }
    std::printf("# 字段：lock/threads/cs/ns_op（每次 lock-unlock 平均纳秒）/throughput_mops/ops\n");

    {
        SpinLock lock;
        sweep("spin", lock);
    }
    {
        StdMutex lock;
        sweep("mutex", lock);
    }
    {
        AdaptiveMutex lock;
        sweep("adaptive", lock);
    }
    std::printf("done sink=%llu\n", static_cast<unsigned long long>(g_sink));
    return 0;
}
