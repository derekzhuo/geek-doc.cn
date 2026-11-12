// 可控数据竞争演示：默认版本两个线程对同一普通 int 无同步自增（TSan 必报）；
// 用 -DRACE_FIXED 编译时改为 std::atomic  relaxed 自增（零报告对照）。
#include <atomic>
#include <iostream>
#include <thread>

#ifdef RACE_FIXED
static std::atomic<int> shared_counter{0};
static void bump() {
    for (int i = 0; i < 1'000'000; ++i)
        shared_counter.fetch_add(1, std::memory_order_relaxed);
}
#else
static int shared_counter = 0;
static void bump() {
    for (int i = 0; i < 1'000'000; ++i) ++shared_counter;
}
#endif

int main() {
    std::thread t1(bump);
    std::thread t2(bump);
    t1.join();
    t2.join();
#ifdef RACE_FIXED
    std::cout << "fixed: shared_counter=" << shared_counter.load() << '\n';
#else
    std::cout << "racy:  shared_counter=" << shared_counter << '\n';
#endif
    return 0;
}
