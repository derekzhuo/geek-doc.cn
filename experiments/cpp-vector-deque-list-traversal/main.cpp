// vector / deque / list 遍历与插入位置成本基准
//   - 同元素量 N 个 int 下比较顺序遍历、头部插入、中间插入与中间删除
//   - 重载全局 operator new/delete，按 malloc 实际块大小统计容器存活期堆占用
//   - 用法：bench [all|vector|deque|list]，单容器模式供 /usr/bin/time -l 取 RSS/缺页
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <deque>
#include <iterator>
#include <list>
#include <malloc/malloc.h>
#include <new>
#include <string>
#include <vector>

namespace {

constexpr int N = 1'000'000;  // 每容器元素量
constexpr int K = 1'000;      // 头部/中间插删次数

std::uint64_t g_new_calls = 0;
std::uint64_t g_new_bytes = 0;
std::uint64_t g_del_bytes = 0;
volatile long long g_sink = 0;

void reset_counters() { g_new_calls = g_new_bytes = g_del_bytes = 0; }

template <class F>
double time_ms(F&& f) {
    auto t0 = std::chrono::steady_clock::now();
    f();
    auto t1 = std::chrono::steady_clock::now();
    return std::chrono::duration<double, std::milli>(t1 - t0).count();
}

template <class Container>
void fill(Container& c) {
    for (int i = 0; i < N; ++i) c.push_back(i);
}

}  // namespace

// ---- 全局 operator new/delete 记账：按 malloc 实际块大小，存活字节可精确相减 ----
void* operator new(std::size_t n) {
    void* p = std::malloc(n);
    if (!p) throw std::bad_alloc();
    g_new_calls += 1;
    g_new_bytes += malloc_size(p);
    return p;
}
void* operator new(std::size_t n, std::nothrow_t const&) noexcept {
    void* p = std::malloc(n);
    if (p) {
        g_new_calls += 1;
        g_new_bytes += malloc_size(p);
    }
    return p;
}
void operator delete(void* p) noexcept {
    if (!p) return;
    g_del_bytes += malloc_size(p);
    std::free(p);
}
void operator delete(void* p, std::size_t) noexcept { operator delete(p); }
void operator delete(void* p, std::nothrow_t const&) noexcept { operator delete(p); }
void* operator new[](std::size_t n) { return operator new(n); }
void* operator new[](std::size_t n, std::nothrow_t const&) noexcept {
    return operator new(n, std::nothrow);
}
void operator delete[](void* p) noexcept { operator delete(p); }
void operator delete[](void* p, std::size_t) noexcept { operator delete(p); }
void operator delete[](void* p, std::nothrow_t const&) noexcept { operator delete(p); }

template <class Container>
void run_container(const char* name) {
    // 1. 存活期堆占用：连续构建到 N 个元素，析构前读 live 字节
    {
        reset_counters();
        Container c;
        fill(c);
        auto live = g_new_bytes - g_del_bytes;
        std::printf("[footprint]  %-11s N=%d: live=%llu B, %.2f B/elem, new_calls=%llu\n",
                    name, N, static_cast<unsigned long long>(live),
                    static_cast<double>(live) / N,
                    static_cast<unsigned long long>(g_new_calls));
    }

    // 2. 顺序遍历：range-for 求和，结果经 volatile 落盘防消除
    {
        Container c;
        fill(c);
        double ms = time_ms([&] {
            long long sum = 0;
            for (int x : c) sum += x;
            g_sink = sum;
        });
        std::printf("[traverse]   %-11s N=%d: %.3f ms\n", name, N, ms);
    }

    // 3. 头部插入 K 次：vector 每次整体后移，deque/list 头部为 O(1) 位置
    {
        Container c;
        fill(c);
        double ms = time_ms([&] {
            for (int j = 0; j < K; ++j) c.insert(c.begin(), j);
        });
        std::printf("[head-ins]   %-11s K=%d at begin: %.3f ms\n", name, K, ms);
    }

    // 4. 中间插入 K 次：迭代器固定在 N/2 附近，insert 返回新元素位置
    {
        Container c;
        fill(c);
        auto it = c.begin();
        std::advance(it, N / 2);
        double ms = time_ms([&] {
            for (int j = 0; j < K; ++j) it = c.insert(it, j);
        });
        std::printf("[mid-ins]    %-11s K=%d at N/2: %.3f ms\n", name, K, ms);
    }

    // 5. 中间删除 K 次：erase 返回后继迭代器，位置始终停在中部
    {
        Container c;
        fill(c);
        auto it = c.begin();
        std::advance(it, N / 2);
        double ms = time_ms([&] {
            for (int j = 0; j < K; ++j) it = c.erase(it);
        });
        std::printf("[mid-erase]  %-11s K=%d at N/2: %.3f ms\n", name, K, ms);
    }
}

int main(int argc, char** argv) {
    std::string mode = argc > 1 ? argv[1] : "all";
    std::printf("# vector/deque/list benchmark N=%d K=%d (%s)\n", N, K, mode.c_str());
    std::printf("# sizeof: vector<int>=%zu deque<int>=%zu list<int>=%zu bytes\n",
                sizeof(std::vector<int>), sizeof(std::deque<int>),
                sizeof(std::list<int>));

    if (mode == "all" || mode == "vector") run_container<std::vector<int>>("vector<int>");
    if (mode == "all" || mode == "deque") run_container<std::deque<int>>("deque<int>");
    if (mode == "all" || mode == "list") run_container<std::list<int>>("list<int>");

    std::printf("sink=%lld\n", static_cast<long long>(g_sink));
    return 0;
}
