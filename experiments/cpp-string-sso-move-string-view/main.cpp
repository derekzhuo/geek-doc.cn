// std::string SSO 阈值、移动成本与 string_view 去拷贝边界实测。
// 重载全局 operator new/delete（含对齐版）统计分配，长度扫档定位 SSO 边界，
// 再用传值/const 引用/string_view 三种接口对照调用成本与分配次数。
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <new>
#include <string>
#include <string_view>
#include <type_traits>

using Clock = std::chrono::steady_clock;

static std::size_t g_alloc_count = 0;
static std::size_t g_alloc_bytes = 0;
static std::size_t g_dealloc_count = 0;
static bool g_track = false;

void* operator new(std::size_t n) {
    if (g_track) { ++g_alloc_count; g_alloc_bytes += n; }
    if (void* p = std::malloc(n)) return p;
    throw std::bad_alloc();
}
void* operator new[](std::size_t n) { return operator new(n); }
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
void* operator new(std::size_t n, std::align_val_t a) {
    if (g_track) { ++g_alloc_count; g_alloc_bytes += n; }
    auto al = static_cast<std::size_t>(a);
    if (auto* p = std::aligned_alloc(al, (n + al - 1) & ~(al - 1))) return p;
    throw std::bad_alloc();
}
void* operator new[](std::size_t n, std::align_val_t a) { return operator new(n, a); }
void operator delete(void* p, std::align_val_t) noexcept { free_tracked(p); }
void operator delete[](void* p, std::align_val_t) noexcept { free_tracked(p); }
void operator delete(void* p, std::size_t, std::align_val_t) noexcept { free_tracked(p); }
void operator delete[](void* p, std::size_t, std::align_val_t) noexcept { free_tracked(p); }

constexpr long CALL_ITERS = 20'000'000;
constexpr long MOVE_ITERS = 10'000'000;
constexpr int SSO_LEN = 12;       // 短串：落在 SSO 区
constexpr int HEAP_LEN = 120;     // 长串：必然堆分配

double elapsed_ms(Clock::time_point t0, Clock::time_point t1) {
    return std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count() / 1000.0;
}

// 三个同语义 sink：只做一点可校验的累加，noinline 保留调用边界。
__attribute__((noinline)) long sink_value(std::string s) {
    long h = 0;
    for (char c : s) h = h * 31 + c;
    return h;
}
__attribute__((noinline)) long sink_cref(const std::string& s) {
    long h = 0;
    for (char c : s) h = h * 31 + c;
    return h;
}
__attribute__((noinline)) long sink_sv(std::string_view s) {
    long h = 0;
    for (char c : s) h = h * 31 + c;
    return h;
}

int main() {
    std::printf("# std::string SSO / 移动 / string_view 基准 (CALL_ITERS=%ld MOVE_ITERS=%ld)\n",
                CALL_ITERS, MOVE_ITERS);
    std::printf("# sizeof(std::string)=%zu sizeof(string_view)=%zu\n\n",
                sizeof(std::string), sizeof(std::string_view));

    // ---- 1) 长度扫档：每个长度构造+析构一次，数分配 ----
    std::puts("# ---- SSO 长度扫档（构造后立即析构的分配次数） ----");
    for (int len = 0; len <= 32; ++len) {
        std::string seed(len, 'a');
        g_alloc_count = g_alloc_bytes = g_dealloc_count = 0;
        g_track = true;
        {
            std::string s(seed);
            if (static_cast<int>(s.size()) != len) std::abort();
        }
        g_track = false;
        std::printf("len=%2d allocs=%zu bytes=%zu deallocs=%zu\n",
                    len, g_alloc_count, g_alloc_bytes, g_dealloc_count);
    }
    std::puts("");

    const std::string short_s(SSO_LEN, 's');
    const std::string long_s(HEAP_LEN, 'l');
    const char* literal = "abcdefghijklmnopqrstuvwxyz0123456789";  // 36 字节，超 SSO

    // ---- 2) 三接口 × 三种实参：分配计数 + 调用耗时 ----
    std::puts("# ---- 接口对照：每次调用的分配次数 ----");
    auto count_allocs = [](const char* tag, auto&& fn) {
        g_alloc_count = g_alloc_bytes = g_dealloc_count = 0;
        g_track = true;
        long sink = 0;
        for (long i = 0; i < 100'000; ++i) sink += fn();
        g_track = false;
        if (sink == 0xdeadbeef) std::abort();
        std::printf("%-34s 10万次调用 allocs=%zu (%.3f/次)\n",
                    tag, g_alloc_count,
                    static_cast<double>(g_alloc_count) / 100'000.0);
    };
    count_allocs("value(短串左值 SSO)", [&] { return sink_value(short_s); });
    count_allocs("value(长串左值 堆)", [&] { return sink_value(long_s); });
    count_allocs("value(长字面量)", [&] { return sink_value(literal); });
    count_allocs("cref(短串左值)", [&] { return sink_cref(short_s); });
    count_allocs("cref(长串左值)", [&] { return sink_cref(long_s); });
    count_allocs("string_view(短串)", [&] { return sink_sv(short_s); });
    count_allocs("string_view(长串)", [&] { return sink_sv(long_s); });
    count_allocs("string_view(字面量)", [&] { return sink_sv(literal); });
    std::puts("");

    std::puts("# ---- 接口对照：2000 万次调用耗时（单次运行 ns/次） ----");
    // 四个等价串按 i&3 轮转，阻止编译器把重复结果提到循环外。
    const std::string short_arr[4] = {short_s, short_s + "b", short_s + "c", short_s + "d"};
    const std::string long_arr[4] = {long_s, long_s + "b", long_s + "c", long_s + "d"};
    const std::string_view sv_short[4] = {short_arr[0], short_arr[1], short_arr[2], short_arr[3]};
    const std::string_view sv_long[4] = {long_arr[0], long_arr[1], long_arr[2], long_arr[3]};
    auto time_calls = [](const char* tag, auto&& fn) {
        volatile long sink = 0;
        auto t0 = Clock::now();
        for (long i = 0; i < CALL_ITERS; ++i) sink = sink + fn(i & 3);
        auto t1 = Clock::now();
        if (sink == 0xdeadbeef) std::abort();
        std::printf("%-34s %.2f ns/次\n", tag, elapsed_ms(t0, t1) * 1e6 / CALL_ITERS);
    };
    time_calls("value(短串左值 SSO)", [&](int k) { return sink_value(short_arr[k]); });
    time_calls("value(长串左值 堆)", [&](int k) { return sink_value(long_arr[k]); });
    time_calls("cref(短串左值)", [&](int k) { return sink_cref(short_arr[k]); });
    time_calls("cref(长串左值)", [&](int k) { return sink_cref(long_arr[k]); });
    time_calls("string_view(短串)", [&](int k) { return sink_sv(sv_short[k]); });
    time_calls("string_view(长串)", [&](int k) { return sink_sv(sv_long[k]); });
    std::puts("");

    // ---- 3) 移动构造：SSO 形态必须搬字节，堆形态只偷指针 ----
    std::puts("# ---- 移动构造耗时与分配 ----");
    auto time_move = [](const char* tag, const std::string& src) {
        g_alloc_count = 0;
        g_track = true;
        volatile std::size_t guard = 0;
        auto t0 = Clock::now();
        for (long i = 0; i < MOVE_ITERS; ++i) {
            std::string tmp(src);       // 每次先复制一个独立对象
            std::string dst(std::move(tmp));
            guard += dst.size();
        }
        auto t1 = Clock::now();
        g_track = false;
        (void)guard;
        std::printf("%-28s %.2f ns/轮（含一次复制+一次移动，区间分配 %zu 次）\n",
                    tag, elapsed_ms(t0, t1) * 1e6 / MOVE_ITERS, g_alloc_count);
    };
    time_move("SSO 串(len=12)", short_s);
    time_move("堆串(len=120)", long_s);
    return 0;
}
