// SPSC/MPSC 无锁消息队列基准对比
// 来源文档：站点 concepts/latency/spsc-mpsc-queue.md「五、性能量化」
//
// 对比：SPSC 无锁环形队列（零 CAS/零回收） vs std::queue + std::mutex
// 编译：g++ -O2 -g -std=c++17 -pthread -o spsc_bench spsc_bench.cpp
// 运行：./spsc_bench [元素数，默认1000000]

#include <atomic>
#include <vector>
#include <cstddef>
#include <optional>
#include <thread>
#include <mutex>
#include <queue>
#include <chrono>
#include <iostream>
#include <cstdlib>

// ---- SPSC 无锁环形队列（CAP 必须为 2 的幂）----
template <typename T, size_t CAP>
class SPSCRingQueue {
    static_assert((CAP & (CAP - 1)) == 0, "CAP must be power of two");
    std::vector<T> buf_{CAP};
    alignas(64) std::atomic<size_t> head_{0};  // 消费者写，与 tail 隔离 cacheline
    alignas(64) std::atomic<size_t> tail_{0};  // 生产者写
    size_t mask_ = CAP - 1;
public:
    bool push(const T& item) {
        size_t t = tail_.load(std::memory_order_relaxed);
        size_t h = head_.load(std::memory_order_acquire);
        if (t - h >= CAP) return false;                 // 已满
        buf_[t & mask_] = item;                         // 先写数据
        tail_.store(t + 1, std::memory_order_release);  // release 发布
        return true;
    }
    std::optional<T> pop() {
        size_t h = head_.load(std::memory_order_relaxed);
        size_t t = tail_.load(std::memory_order_acquire);
        if (h == t) return std::nullopt;                // 已空
        T item = buf_[h & mask_];
        head_.store(h + 1, std::memory_order_release);
        return item;
    }
};

// ---- 有锁队列（对照组）----
template <typename T>
class LockQueue {
    std::mutex mtx_;
    std::queue<T> q_;
public:
    void push(T item) {
        std::lock_guard<std::mutex> lk(mtx_);
        q_.push(std::move(item));
    }
    std::optional<T> pop() {
        std::lock_guard<std::mutex> lk(mtx_);
        if (q_.empty()) return std::nullopt;
        T item = std::move(q_.front());
        q_.pop();
        return item;
    }
};

int main(int argc, char** argv) {
    const size_t N = argc > 1 ? std::strtoull(argv[1], nullptr, 10) : 1000000;
    const size_t CAP = 1u << 20;  // 1M 槽位

    // ---- SPSC 无锁 ----
    SPSCRingQueue<int, CAP> spsc;
    auto t0 = std::chrono::high_resolution_clock::now();
    std::thread prod([&] { for (size_t i = 0; i < N; ++i) while (!spsc.push((int)i)); });
    std::thread cons([&] {
        size_t got = 0;
        while (got < N) { if (spsc.pop()) ++got; }
    });
    prod.join(); cons.join();
    auto t1 = std::chrono::high_resolution_clock::now();
    double spsc_us = std::chrono::duration<double, std::micro>(t1 - t0).count();

    // ---- 有锁 ----
    LockQueue<int> lq;
    auto u0 = std::chrono::high_resolution_clock::now();
    std::thread lprod([&] { for (size_t i = 0; i < N; ++i) lq.push((int)i); });
    std::thread lcons([&] {
        size_t got = 0;
        while (got < N) { if (lq.pop()) ++got; }
    });
    lprod.join(); lcons.join();
    auto u1 = std::chrono::high_resolution_clock::now();
    double lock_us = std::chrono::duration<double, std::micro>(u1 - u0).count();

    auto fmt = [](double us) { return (N * 2.0) / (us / 1e6) / 1e6; };  // M ops/s
    std::cout << "SPSC 无锁环形 : " << spsc_us / 1e3 << " ms, "
              << fmt(spsc_us) << " M ops/s" << std::endl;
    std::cout << "有锁 queue    : " << lock_us / 1e3 << " ms, "
              << fmt(lock_us) << " M ops/s" << std::endl;
    std::cout << "加速比        : " << lock_us / spsc_us << "x" << std::endl;
    return 0;
}
