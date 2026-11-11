// placement new 固定块对象池 vs 裸 new/delete 基准
// 测量两条口径：
//   1) 高频 create/destroy 的纯吞吐（ns/次、百万次耗时），进程内重复 5 轮取中位
//   2) 分配与构造分解：重载 operator new 数堆分配次数，Tracked 静态计数 ctor/dtor
// 另含池槽位耗尽策略的行为演示。
#include <new>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <chrono>
#include <stdexcept>
#include <string>
#include <algorithm>
#include <vector>

// ---------- 全局堆分配计数：重载普通版与对齐版 operator new/delete ----------
static bool g_counting = false;
static uint64_t g_alloc_calls = 0;
static uint64_t g_alloc_bytes = 0;
static uint64_t g_free_calls = 0;

static void* counted_malloc(std::size_t n) {
    if (g_counting) {
        ++g_alloc_calls;
        g_alloc_bytes += n;
    }
    void* p = std::malloc(n);
    if (!p) throw std::bad_alloc();
    return p;
}

void* operator new(std::size_t n) { return counted_malloc(n); }
void* operator new[](std::size_t n) { return counted_malloc(n); }
void* operator new(std::size_t n, std::align_val_t a) {
    if (g_counting) {
        ++g_alloc_calls;
        g_alloc_bytes += n;
    }
    void* p = nullptr;
    if (posix_memalign(&p, static_cast<std::size_t>(a), n) != 0)
        throw std::bad_alloc();
    return p;
}
void* operator new[](std::size_t n, std::align_val_t a) {
    return operator new(n, a);
}

static void counted_free(void* p) noexcept {
    if (g_counting && p) ++g_free_calls;
    std::free(p);
}

void operator delete(void* p) noexcept { counted_free(p); }
void operator delete[](void* p) noexcept { counted_free(p); }
void operator delete(void* p, std::size_t) noexcept { counted_free(p); }
void operator delete[](void* p, std::size_t) noexcept { counted_free(p); }
void operator delete(void* p, std::align_val_t) noexcept { counted_free(p); }
void operator delete[](void* p, std::align_val_t) noexcept { counted_free(p); }
void operator delete(void* p, std::size_t, std::align_val_t) noexcept { counted_free(p); }
void operator delete[](void* p, std::size_t, std::align_val_t) noexcept { counted_free(p); }

// ---------- 可计数业务对象：非平凡构造/析构，48 字节 ----------
struct Widget {
    static uint64_t ctor_calls;
    static uint64_t dtor_calls;
    int a;
    int b;
    int c;
    uint64_t tag;
    char pad[28];

    explicit Widget(int x = 0) : a(x), b(x * 2), c(x + 1),
                                 tag(0x5A5A000000000000ULL | static_cast<uint64_t>(x)) {
        for (int i = 0; i < 28; ++i) pad[i] = static_cast<char>(x + i);
        ++ctor_calls;
    }
    ~Widget() {
        tag = 0;
        ++dtor_calls;
    }
    int value() const { return a + b + c + static_cast<int>(pad[0]); }
};
uint64_t Widget::ctor_calls = 0;
uint64_t Widget::dtor_calls = 0;

// ---------- 固定块对象池：一次大块分配 + placement new 构造 + 侵入式 free list ----------
struct PoolExhausted : std::runtime_error {
    PoolExhausted() : std::runtime_error("object pool exhausted") {}
};

template <class T, std::size_t Capacity>
class ObjectPool {
public:
    ObjectPool() : head_(NONE), used_(0) {
        // 只分配未构造的原始存储，全程只有这一次堆分配
        storage_ = static_cast<char*>(::operator new(Capacity * sizeof(T)));
        for (std::size_t i = 0; i < Capacity; ++i) release_slot(i);
    }
    ~ObjectPool() {
        ::operator delete(storage_);  // 存活对象应由调用方先 release，此处仅归还原始存储
    }
    ObjectPool(const ObjectPool&) = delete;
    ObjectPool& operator=(const ObjectPool&) = delete;

    template <class... Args>
    T* alloc(Args&&... args) {
        if (head_ == NONE) throw PoolExhausted();
        std::size_t idx = head_;
        head_ = *slot_next(idx);
        ++used_;
        // 只构造、不分配：placement new 在既有槽位上调构造函数
        return ::new (static_cast<void*>(slot(idx))) T(std::forward<Args>(args)...);
    }

    void release(T* p) {
        std::ptrdiff_t off = static_cast<char*>(static_cast<void*>(p)) - storage_;
        std::size_t idx = static_cast<std::size_t>(off) / sizeof(T);
        p->~T();  // 显式析构，内存不归还分配器
        release_slot(idx);
        --used_;
    }

    std::size_t capacity() const { return Capacity; }
    std::size_t used() const { return used_; }

private:
    static constexpr std::size_t NONE = static_cast<std::size_t>(-1);
    char* storage_;
    std::size_t head_;
    std::size_t used_;

    char* slot(std::size_t i) { return storage_ + i * sizeof(T); }
    std::size_t* slot_next(std::size_t i) {
        return reinterpret_cast<std::size_t*>(static_cast<void*>(slot(i)));
    }
    void release_slot(std::size_t i) {
        *slot_next(i) = head_;
        head_ = i;
    }
};

// ---------- 计时工具 ----------
using Clock = std::chrono::steady_clock;

static volatile int g_sink = 0;

// 逃逸屏障：强制指针被真实使用，阻止编译器把不逃逸的 new/delete 对
// 优化成栈对象（clang 的 heap-to-stack 变换），两条被测路径对称施加。
static inline void escape_barrier(const void* p) {
    asm volatile("" : : "r"(p) : "memory");
}

template <class Fn>
static double time_ns_per_op(Fn&& fn, std::size_t iters) {
    auto t0 = Clock::now();
    int sum = fn();
    auto t1 = Clock::now();
    g_sink += sum;
    return std::chrono::duration<double, std::nano>(t1 - t0).count() /
           static_cast<double>(iters);
}

static double median_of(std::vector<double> v) {
    std::sort(v.begin(), v.end());
    return v[v.size() / 2];
}

static constexpr std::size_t ITERS = 1'000'000;
static constexpr std::size_t CAP = 4096;
static constexpr std::size_t LIVE = 256;
static constexpr int REPEATS = 5;

using Pool = ObjectPool<Widget, CAP>;

// 场景一：每次迭代 alloc 后立刻 release，最大存活数为 1
static int churn_pool() {
    Pool pool;
    int sum = 0;
    for (std::size_t i = 0; i < ITERS; ++i) {
        Widget* w = pool.alloc(static_cast<int>(i & 0xFF));
        escape_barrier(w);
        sum += w->value();
        pool.release(w);
    }
    return sum;
}
static int churn_raw() {
    int sum = 0;
    for (std::size_t i = 0; i < ITERS; ++i) {
        Widget* w = new Widget(static_cast<int>(i & 0xFF));
        escape_barrier(w);
        sum += w->value();
        delete w;
    }
    return sum;
}

// 场景二：保持 LIVE 个存活对象，每迭代补一个、销一个，稳态轮换
static int steady_pool() {
    Pool pool;
    Widget* live[LIVE] = {};
    for (std::size_t k = 0; k < LIVE; ++k) live[k] = pool.alloc(static_cast<int>(k));
    int sum = 0;
    for (std::size_t i = 0; i < ITERS; ++i) {
        std::size_t slot = i % LIVE;
        pool.release(live[slot]);
        live[slot] = pool.alloc(static_cast<int>(i & 0xFF));
        sum += live[slot]->value();
    }
    for (Widget* w : live) pool.release(w);
    return sum;
}
static int steady_raw() {
    Widget* live[LIVE] = {};
    for (std::size_t k = 0; k < LIVE; ++k) live[k] = new Widget(static_cast<int>(k));
    int sum = 0;
    for (std::size_t i = 0; i < ITERS; ++i) {
        std::size_t slot = i % LIVE;
        delete live[slot];
        live[slot] = new Widget(static_cast<int>(i & 0xFF));
        sum += live[slot]->value();
    }
    for (Widget* w : live) delete w;
    return sum;
}

struct Account {
    uint64_t alloc_calls;
    uint64_t alloc_bytes;
    uint64_t free_calls;
    uint64_t ctor;
    uint64_t dtor;
};

template <class Fn>
static Account count_pass(Fn&& fn) {
    g_alloc_calls = g_alloc_bytes = g_free_calls = 0;
    Widget::ctor_calls = Widget::dtor_calls = 0;
    g_counting = true;
    g_sink += fn();
    g_counting = false;
    return {g_alloc_calls, g_alloc_bytes, g_free_calls,
            Widget::ctor_calls, Widget::dtor_calls};
}

static void exhaustion_demo() {
    ObjectPool<Widget, 4> tiny;
    Widget* held[4] = {};
    for (int i = 0; i < 4; ++i) held[i] = tiny.alloc(i);
    printf("[exhaust] 容量 4 已取 %zu 个，第 5 次 alloc：", tiny.used());
    try {
        (void)tiny.alloc(99);
        printf("未抛异常（意外）\n");
    } catch (const PoolExhausted& e) {
        printf("抛 %s（符合预期）\n", e.what());
    }
    tiny.release(held[1]);
    Widget* again = tiny.alloc(7);
    printf("[exhaust] 释放 1 个槽位后重新 alloc 成功，池内存活 %zu 个\n", tiny.used());
    tiny.release(again);
    for (int i = 0; i < 4; ++i) {
        if (i == 1) continue;
        tiny.release(held[i]);
    }
    printf("[exhaust] 全部归还后池内存活 %zu 个，ctor=%llu dtor=%llu\n",
           tiny.used(),
           static_cast<unsigned long long>(Widget::ctor_calls),
           static_cast<unsigned long long>(Widget::dtor_calls));
}

int main() {
    printf("==== placement new 对象池 vs 裸 new/delete 基准 ====\n");
    printf("sizeof(Widget)=%zu, pool capacity=%zu (%zu 字节/块), iters=%zu, repeats=%d\n",
           sizeof(Widget), CAP, CAP * sizeof(Widget), ITERS, REPEATS);
    printf("\n# ---- throughput: 进程内 %d 轮取中位 ----\n", REPEATS);

    struct Case { const char* tag; const char* name; int (*fn)(); };
    Case cases[] = {
        {"churn",  "pool", churn_pool},
        {"churn",  "raw ", churn_raw},
        {"steady", "pool", steady_pool},
        {"steady", "raw ", steady_raw},
    };
    for (const Case& c : cases) {
        std::vector<double> samples;
        for (int r = 0; r < REPEATS; ++r)
            samples.push_back(time_ns_per_op(c.fn, ITERS));
        double med = median_of(samples);
        printf("[%s|%s] 中位 %.2f ns/次，百万次约 %.3f ms（五轮：",
               c.tag, c.name, med, med * ITERS / 1e6);
        for (double v : samples) printf(" %.2f", v);
        printf(" ）\n");
    }

    printf("\n# ---- accounting: 百万次 create/destroy 的分配/构造计数 ----\n");
    Account a1 = count_pass(churn_pool);
    printf("[churn|pool] heap alloc=%llu 次/%llu 字节, free=%llu 次, ctor=%llu, dtor=%llu\n",
           (unsigned long long)a1.alloc_calls, (unsigned long long)a1.alloc_bytes,
           (unsigned long long)a1.free_calls,
           (unsigned long long)a1.ctor, (unsigned long long)a1.dtor);
    Account a2 = count_pass(churn_raw);
    printf("[churn|raw ] heap alloc=%llu 次/%llu 字节, free=%llu 次, ctor=%llu, dtor=%llu\n",
           (unsigned long long)a2.alloc_calls, (unsigned long long)a2.alloc_bytes,
           (unsigned long long)a2.free_calls,
           (unsigned long long)a2.ctor, (unsigned long long)a2.dtor);
    Account a3 = count_pass(steady_pool);
    printf("[steady|pool] heap alloc=%llu 次/%llu 字节, free=%llu 次, ctor=%llu, dtor=%llu\n",
           (unsigned long long)a3.alloc_calls, (unsigned long long)a3.alloc_bytes,
           (unsigned long long)a3.free_calls,
           (unsigned long long)a3.ctor, (unsigned long long)a3.dtor);
    Account a4 = count_pass(steady_raw);
    printf("[steady|raw ] heap alloc=%llu 次/%llu 字节, free=%llu 次, ctor=%llu, dtor=%llu\n",
           (unsigned long long)a4.alloc_calls, (unsigned long long)a4.alloc_bytes,
           (unsigned long long)a4.free_calls,
           (unsigned long long)a4.ctor, (unsigned long long)a4.dtor);

    printf("\n# ---- exhaustion: 槽位耗尽与回收复用 ----\n");
    Widget::ctor_calls = Widget::dtor_calls = 0;
    exhaustion_demo();

    printf("\nsink=%d\n", g_sink);
    return 0;
}
