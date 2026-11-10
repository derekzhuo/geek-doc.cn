// std::function 小对象缓冲（SBO）阈值实测：
// 逐级增大捕获体，重载全局 operator new/delete 计数，定位从栈上缓冲
// 滑向堆分配的边界；另用过对齐类型与非 noexcept 移动类型做两个机制反证。
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <new>
#include <type_traits>

using Clock = std::chrono::steady_clock;

static std::size_t g_alloc_count = 0;
static std::size_t g_alloc_bytes = 0;
static std::size_t g_dealloc_count = 0;
static bool g_track = false;  // 只统计测量段内的分配，避开启动期噪声

void* operator new(std::size_t n) {
    if (g_track) { ++g_alloc_count; g_alloc_bytes += n; }
    if (void* p = std::malloc(n)) return p;
    throw std::bad_alloc();
}
void* operator new[](std::size_t n) {
    if (g_track) { ++g_alloc_count; g_alloc_bytes += n; }
    if (void* p = std::malloc(n)) return p;
    throw std::bad_alloc();
}
static void free_tracked(void* p) {
    if (p) {
        if (g_track) ++g_dealloc_count;
        std::free(p);
    }
}
void operator delete(void* p) noexcept { free_tracked(p); }
void operator delete[](void* p) noexcept { free_tracked(p); }
void operator delete(void* p, std::size_t) noexcept { free_tracked(p); }
void operator delete[](void* p, std::size_t) noexcept { free_tracked(p); }

// 对齐版：过对齐可调用体若被挤到堆上，走的是这一组而不是上面的普通版。
void* operator new(std::size_t n, std::align_val_t a) {
    if (g_track) { ++g_alloc_count; g_alloc_bytes += n; }
    if (auto p = std::aligned_alloc(static_cast<std::size_t>(a),
                                    (n + static_cast<std::size_t>(a) - 1) & ~(static_cast<std::size_t>(a) - 1)))
        return p;
    throw std::bad_alloc();
}
void* operator new[](std::size_t n, std::align_val_t a) { return operator new(n, a); }
void operator delete(void* p, std::align_val_t) noexcept { free_tracked(p); }
void operator delete[](void* p, std::align_val_t) noexcept { free_tracked(p); }
void operator delete(void* p, std::size_t, std::align_val_t) noexcept { free_tracked(p); }
void operator delete[](void* p, std::size_t, std::align_val_t) noexcept { free_tracked(p); }

// 常规捕获体：尺寸由模板参数 N 决定，移动构造默认 noexcept。
template <std::size_t N>
struct Capture {
    char data[N > 0 ? N : 1];
    int token = 7;
    int operator()(int x) const noexcept { return x + token; }
};

// 机制反证一：尺寸很小但过对齐，超出 std::function 缓冲的对齐承诺。
struct alignas(64) OverAligned {
    int token = 7;
    int operator()(int x) const noexcept { return x + token; }
};

// 机制反证二：尺寸很小、移动构造非 noexcept，库无法在缓冲内安全重定位。
struct RiskyMove {
    char data[8];
    int token = 7;
    RiskyMove() = default;
    RiskyMove(const RiskyMove&) = default;
    RiskyMove(RiskyMove&&) noexcept(false) {}
    RiskyMove& operator=(const RiskyMove&) = default;
    RiskyMove& operator=(RiskyMove&&) noexcept(false) { return *this; }
    int operator()(int x) const noexcept { return x + token; }
};

constexpr long CALL_ITERS = 20'000'000;
constexpr long CTOR_ITERS = 2'000'000;

// 运行期种子：防止编译器把 token=7 常量传播后整段构造循环消掉。
volatile int g_seed = 7;

double elapsed_ms(Clock::time_point t0, Clock::time_point t1) {
    return std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count() / 1000.0;
}

template <class F>
void probe(const char* tag) {
    using Fn = std::function<int(int)>;
    std::printf("# ---- %s sizeof=%zu alignof=%zu nothrow_move=%d ----\n",
                tag, sizeof(F), alignof(F), std::is_nothrow_move_constructible<F>::value);

    // 1) 单次构造的分配计数（f 析构在作用域结束时发生）
    g_alloc_count = g_alloc_bytes = g_dealloc_count = 0;
    g_track = true;
    {
        F target;
        target.token = g_seed;
        Fn f(target);
        std::printf("construct: allocs=%zu bytes=%zu", g_alloc_count, g_alloc_bytes);
    }
    std::printf(" deallocs_after_dtor=%zu\n", g_dealloc_count);
    g_track = false;

    // 2) 移动构造的分配计数（SBO 走缓冲搬运，堆形态只偷指针）
    g_track = true;
    std::size_t move_allocs;
    {
        F target;
        target.token = g_seed;
        Fn f(target);
        g_alloc_count = g_alloc_bytes = g_dealloc_count = 0;  // 隔离 f 构造，只看移动本身
        Fn g(std::move(f));
        move_allocs = g_alloc_count;
        std::printf("move-construct: allocs=%zu bytes=%zu\n", move_allocs, g_alloc_bytes);
    }
    g_track = false;

    // 3) 反复构造/析构的单位成本
    g_alloc_count = g_alloc_bytes = g_dealloc_count = 0;
    g_track = true;
    auto t0 = Clock::now();
    for (long i = 0; i < CTOR_ITERS; ++i) {
        F target;
        target.token = g_seed;
        Fn f(target);
        if (f(i & 255) != (i & 255) + g_seed) std::abort();
    }
    auto t1 = Clock::now();
    const double ctor_ms = elapsed_ms(t0, t1);
    const std::size_t ctor_allocs = g_alloc_count;
    g_track = false;

    // 4) 调用成本（构造一次，热循环只做 operator()）
    F target;
    target.token = g_seed;
    Fn f(target);
    long sink = 0;
    auto t2 = Clock::now();
    for (long i = 0; i < CALL_ITERS; ++i) sink += f(i & 255);
    auto t3 = Clock::now();
    const double call_ms = elapsed_ms(t2, t3);
    if (sink == 0xdeadbeef) std::abort();

    std::printf("ctor/dtor x%ld: %.3f ms (%.2f ns/次, 分配 %zu 次, %.3f 次/构造)\n",
                CTOR_ITERS, ctor_ms, ctor_ms * 1e6 / CTOR_ITERS,
                ctor_allocs, static_cast<double>(ctor_allocs) / CTOR_ITERS);
    std::printf("call x%ld: %.3f ms (%.2f ns/次)\n\n",
                CALL_ITERS, call_ms, call_ms * 1e6 / CALL_ITERS);
}

// 无捕获 lambda 与裸函数指针：std::function 的最轻形态基线
static int bare_func(int x) noexcept { return x + 7; }

int main() {
    std::printf("# std::function SBO 阈值基准 (CALL_ITERS=%ld CTOR_ITERS=%ld)\n",
                CALL_ITERS, CTOR_ITERS);
    std::printf("# 编译器宏: __clang_major__=%d _LIBCPP_VERSION=%d\n\n",
#ifdef __clang_major__
                __clang_major__,
#else
                0,
#endif
#ifdef _LIBCPP_VERSION
                _LIBCPP_VERSION
#else
                0
#endif
                );

    // 基线：函数指针与无捕获 lambda
    {
        using Fn = std::function<int(int)>;
        Fn fp(bare_func);
        Fn empty_lambda([](int x) { return x + 7; });
        long sink = 0;
        auto t0 = Clock::now();
        for (long i = 0; i < CALL_ITERS; ++i) sink += fp(i & 255);
        auto t1 = Clock::now();
        for (long i = 0; i < CALL_ITERS; ++i) sink += empty_lambda(i & 255);
        auto t2 = Clock::now();
        if (sink == 0xdeadbeef) std::abort();
        std::printf("# ---- 基线 ----\n");
        std::printf("function_ptr call: %.2f ns/次\n", elapsed_ms(t0, t1) * 1e6 / CALL_ITERS);
        std::printf("empty_lambda  call: %.2f ns/次\n\n", elapsed_ms(t1, t2) * 1e6 / CALL_ITERS);
    }

    probe<Capture<1>>("Capture<1>");
    probe<Capture<8>>("Capture<8>");
    probe<Capture<16>>("Capture<16>");
    probe<Capture<20>>("Capture<20>");
    probe<Capture<24>>("Capture<24>");
    probe<Capture<32>>("Capture<32>");
    probe<Capture<40>>("Capture<40>");
    probe<Capture<48>>("Capture<48>");
    probe<Capture<64>>("Capture<64>");
    probe<OverAligned>("OverAligned(16B/align64)");
    probe<RiskyMove>("RiskyMove(8B, 非noexcept移动)");
    return 0;
}
