#include <chrono>
#include <cstdio>
#include <type_traits>
#include <vector>

#include "widgets.hpp"

using Clock = std::chrono::steady_clock;

static double elapsed_ms(Clock::time_point t0, Clock::time_point t1) {
    return std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count()
           / 1000.0;
}

template <class T>
static long long grow(long long n, bool trace, const char* tag) {
    g_counter.reset();
    std::vector<T> v;
    std::size_t last_cap = 0;
    const auto t0 = Clock::now();
    for (long long i = 0; i < n; ++i) {
        v.push_back(T(static_cast<int>(i & 0x7fffffff)));
        if (trace && v.capacity() != last_cap) {
            std::printf("trace %-5s size=%4zu cap=%4zu copy=%lld move=%lld\n",
                        tag, v.size(), v.capacity(),
                        g_counter.copy_ctor, g_counter.move_ctor);
            last_cap = v.capacity();
        }
    }
    const auto t1 = Clock::now();
    std::printf("grow  %-5s n=%lld elapsed_ms=%8.3f copy_ctor=%lld move_ctor=%lld "
                "param_ctor=%lld final_cap=%zu\n",
                tag, n, elapsed_ms(t0, t1),
                g_counter.copy_ctor, g_counter.move_ctor,
                g_counter.param_ctor, v.capacity());
    return g_counter.copy_ctor + g_counter.move_ctor;
}

int main() {
    std::printf("# RVO/NRVO/移动语义与 vector 扩容基准\n");
    std::printf("is_nothrow_move_constructible SafeWidget=%d RiskyWidget=%d\n",
                static_cast<int>(std::is_nothrow_move_constructible<SafeWidget>::value),
                static_cast<int>(std::is_nothrow_move_constructible<RiskyWidget>::value));

    // 场景一：纯右值返回，期望只构造一次，复制/移动计数为 0（C++17 保证）。
    g_counter.reset();
    {
        SafeWidget w = makeSafeRVO(7);
        std::printf("rvo        param=%lld copy=%lld move=%lld (id=%d)\n",
                    g_counter.param_ctor, g_counter.copy_ctor,
                    g_counter.move_ctor, w.id);
    }

    // 场景二：具名局部返回，NRVO 命中时同样只构造一次。
    g_counter.reset();
    {
        SafeWidget w = makeSafeNRVO(7);
        std::printf("nrvo       param=%lld copy=%lld move=%lld (id=%d)\n",
                    g_counter.param_ctor, g_counter.copy_ctor,
                    g_counter.move_ctor, w.id);
    }

    std::puts("\n# 小规模扩容轨迹（N=20，每次 capacity 变化打印一行）");
    grow<SafeWidget>(20, true, "safe");
    std::puts("---");
    grow<RiskyWidget>(20, true, "risky");

    std::puts("\n# 大规模扩容计时（N=200000，二进制内预热一次）");
    grow<SafeWidget>(200000, false, "safe-warm");
    grow<RiskyWidget>(200000, false, "risky-warm");
    grow<SafeWidget>(200000, false, "safe");
    grow<RiskyWidget>(200000, false, "risky");
    return 0;
}
