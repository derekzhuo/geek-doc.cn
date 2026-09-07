// 忙等待 vs 睡眠调度：两种线程同步等待模型的延迟/CPU 开销对比
// 来源文档：站点 concepts/latency/low-latency-patterns.md「忙等待 vs 睡眠调度」
//
// 编译：g++ -O2 -o busy_wait_vs_sleep busy_wait_vs_sleep.cpp -pthread
// 运行：./busy_wait_vs_sleep

#include <chrono>
#include <thread>
#include <atomic>
#include <mutex>
#include <condition_variable>
#include <iostream>

const int ITERATIONS = 1000000;

// 忙等待测试：主线程与工作线程通过 spin 标志同步
long long test_busy_wait() {
    std::atomic<bool> flag = false;
    auto start = std::chrono::high_resolution_clock::now();
    std::thread t([&flag]() {
        for (int i = 0; i < ITERATIONS; ++i) {
            while (!flag.load(std::memory_order_acquire)) {
                // 忙等待
            }
            flag.store(false, std::memory_order_release);
        }
    });
    for (int i = 0; i < ITERATIONS; ++i) {
        flag.store(true, std::memory_order_release);
        while (flag.load(std::memory_order_acquire)) {
            // 忙等待
        }
    }
    t.join();
    auto end = std::chrono::high_resolution_clock::now();
    return std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
}

// 睡眠调度测试：主线程与工作线程通过 mutex + condition_variable 同步
long long test_sleep_wait() {
    std::mutex mtx;
    std::condition_variable cv;
    bool flag = false;
    auto start = std::chrono::high_resolution_clock::now();
    std::thread t([&]() {
        std::unique_lock<std::mutex> lock(mtx);
        for (int i = 0; i < ITERATIONS; ++i) {
            cv.wait(lock, [&] { return flag; });
            flag = false;
            cv.notify_one();
        }
    });
    std::unique_lock<std::mutex> lock(mtx);
    for (int i = 0; i < ITERATIONS; ++i) {
        flag = true;
        cv.notify_one();
        cv.wait(lock, [&] { return !flag; });
    }
    t.join();
    auto end = std::chrono::high_resolution_clock::now();
    return std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
}

int main() {
    auto busy = test_busy_wait();
    auto sleep_wait = test_sleep_wait();
    std::cout << "忙等待  总耗时: " << busy << "us, 单次: "
              << (double)busy / ITERATIONS << "us" << std::endl;
    std::cout << "睡眠调度总耗时: " << sleep_wait << "us, 单次: "
              << (double)sleep_wait / ITERATIONS << "us" << std::endl;
    return 0;
}
