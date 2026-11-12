// 同一工作负载、四种插桩构建同口径测量 Sanitizer 运行时开销。
// 四个阶段：真实分配/释放（吃 ASan 拦截器）、大数组遍历（吃影子内存检查）、
// 密集整数算术（吃 UBSan 逐操作检查）、多线程原子计数（吃 TSan happens-before 追踪）。
// 所有变体输出同一 checksum，先证语义等价再谈快慢。
#include <atomic>
#include <chrono>
#include <cstdint>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

namespace {

constexpr int ALLOC_ROUNDS = 2000;
constexpr std::size_t ARRAY_N = 4'000'000;
constexpr long ARITH_OPS = 40'000'000;
constexpr int THREADS = 4;
constexpr long PER_THREAD_INC = 1'000'000;

struct Node {
    long v;
    Node* next;
};

// 阶段一：真实 malloc/free 流量——字符串构造拼接 + 链表头插销毁。
__attribute__((noinline)) long phase_alloc(unsigned seed) {
    long sink = 0;
    for (int r = 0; r < ALLOC_ROUNDS; ++r) {
        std::vector<std::string> bag;
        bag.reserve(16);
        for (int i = 0; i < 16; ++i) {
            std::string s = "item-";
            s += std::to_string(seed + r * 16 + i);
            s += "-tail";
            bag.push_back(s);
        }
        Node* head = nullptr;
        for (int i = 0; i < 32; ++i) {
            head = new Node{static_cast<long>(r) * 32 + i, head};
        }
        for (Node* p = head; p;) {
            sink += p->v;
            Node* dead = p;
            p = p->next;
            delete dead;
        }
        for (const auto& s : bag) sink += s.size();
    }
    return sink;
}

// 阶段二：16 MB 数组多趟读写，影子内存检查密集命中。
__attribute__((noinline)) long phase_array() {
    std::vector<int> data(ARRAY_N);
    for (std::size_t i = 0; i < ARRAY_N; ++i) data[i] = static_cast<int>(i & 0xffff);
    long sink = 0;
    for (int pass = 0; pass < 3; ++pass) {
        for (std::size_t i = 0; i < ARRAY_N; ++i) {
            data[i] = data[i] * 3 + pass;
            sink += data[i];
        }
    }
    return sink;
}

// 阶段三：4000 万次带符号加乘，全程保持合法区间（不触发报告，只承担插桩检查）。
__attribute__((noinline)) long phase_arith(unsigned seed) {
    std::int32_t x = static_cast<std::int32_t>(seed & 0x7fffffff);
    long sink = 0;
    for (long i = 0; i < ARITH_OPS; ++i) {
        x = static_cast<std::int32_t>((static_cast<long>(x) * 1103515245L + 12345L) & 0x7fffffffL);
        sink += (x & 7) + (i & 3);
    }
    return sink + x;
}

// 阶段四：4 线程原子计数 + 线程内向量求和，触发线程创建与同步插桩。
__attribute__((noinline)) long phase_threads() {
    std::atomic<int> shared{0};
    std::vector<long> partial(THREADS, 0);
    std::vector<std::thread> pool;
    for (int t = 0; t < THREADS; ++t) {
        pool.emplace_back([&, t] {
            long local = 0;
            for (long i = 0; i < PER_THREAD_INC; ++i) {
                shared.fetch_add(1, std::memory_order_relaxed);
                local += i & 0x3f;
            }
            partial[t] = local;
        });
    }
    for (auto& th : pool) th.join();
    long total = shared.load();
    for (long v : partial) total += v;
    return total;
}

}  // namespace

int main() {
    const auto t0 = std::chrono::steady_clock::now();
    long checksum = phase_alloc(17);
    checksum = checksum * 31 + phase_array();
    checksum = checksum * 31 + phase_arith(17);
    checksum = checksum * 31 + phase_threads();
    const auto t1 = std::chrono::steady_clock::now();
    const double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    std::cout << "elapsed_ms=" << ms << " checksum=" << checksum << '\n';
    return 0;
}
