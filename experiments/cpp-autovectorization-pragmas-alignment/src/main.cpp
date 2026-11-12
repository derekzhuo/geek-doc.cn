#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>

#include "loops.hpp"

namespace {

constexpr std::size_t N = 1u << 18;       // 262144 个元素
constexpr int PASSES = 200;                // 每轮测量的重复遍数

alignas(64) double g_da[N + 1];
alignas(64) double g_db[N];
alignas(64) long g_la[N];
alignas(64) long g_lx[N];
alignas(64) long g_lv[N];
alignas(64) long g_idx[N];

using clock_type = std::chrono::steady_clock;

double to_ms(clock_type::duration d) {
    return std::chrono::duration<double, std::milli>(d).count();
}

void fill_inputs() {
    for (std::size_t i = 0; i < N; ++i) {
        g_da[i] = static_cast<double>(i % 17) * 0.125 - 1.0;
        g_db[i] = static_cast<double>(i % 13) * 0.0625 - 0.4;
        g_la[i] = static_cast<long>(i % 101) - 50;
        g_lx[i] = static_cast<long>(i % 7) - 3;
        g_idx[i] = static_cast<long>((i * 7919ULL) % N);
        g_lv[i] = 0;
    }
    g_da[N] = 0.0;
}

// setup 在计时区外执行，计时区里只有被测循环本身；
// checksum 在预热之后取值，确保读到的是真实计算结果。
template <class Setup, class Fn, class Cs>
void time_group(const char* name, Setup&& setup, Fn&& fn, Cs&& checksum) {
    setup();
    fn();  // 预热，保证代码页与缓存进入稳态
    auto t0 = clock_type::now();
    for (int p = 0; p < PASSES; ++p) {
        setup();
        fn();
    }
    auto t1 = clock_type::now();
    double ms_per_pass = to_ms(t1 - t0) / PASSES;
    std::printf("%-22s ns/pass=%10.4f checksum=%ld\n",
                name, ms_per_pass * 1e6, checksum());
}

void noop_setup() {}

}  // namespace

int main() {
    fill_inputs();

    // G1 AXPY（restrict）
    time_group("g1_axpy_restrict", fill_inputs,
               [&] { g1_axpy_restrict(g_da, g_db, 1.5, N); },
               [&] { return static_cast<long>(g_da[N / 2] * 1000.0); });

    // G2 整数归约
    long s2 = 0;
    time_group("g2_isum", noop_setup,
               [&] { s2 = g2_isum(g_la, N); }, [&] { return s2; });

    // G3 递推
    time_group("g3_recurrence", fill_inputs,
               [&] { g3_recurrence(g_da, N); },
               [&] { return static_cast<long>(g_da[N - 1] * 1000.0); });

    // G4 裸指针别名版本
    time_group("g4_alias", fill_inputs,
               [&] { g4_alias(g_da, g_db, N); },
               [&] { return static_cast<long>(g_da[N / 2] * 1000.0); });

    // G5 分散写
    auto zero_lv = [] {
        for (std::size_t i = 0; i < N; ++i) g_lv[i] = 0;
    };
    time_group("g5_scatter", zero_lv,
               [&] { g5_scatter(g_lv, g_idx, g_lx, N); },
               [&] { return g_lv[g_idx[3]]; });

    // G6 浮点归约严格模式
    double s6 = 0.0;
    time_group("g6_fpsum_strict", noop_setup,
               [&] { s6 = g6_fpsum_strict(g_db, N); },
               [&] { return static_cast<long>(s6 * 1000.0); });

    // G7 同一归约加 pragma
    double s7 = 0.0;
    time_group("g7_fpsum_pragma", noop_setup,
               [&] { s7 = g7_fpsum_pragma(g_db, N); },
               [&] { return static_cast<long>(s7 * 1000.0); });

    // G8 对齐 vs 错位（错位指针 = 64B 对齐基址偏移 8 字节）
    double s8a = 0.0, s8m = 0.0;
    time_group("g8_aligned", noop_setup,
               [&] { s8a = g8_aligned_sum(g_da, N); },
               [&] { return static_cast<long>(s8a * 1000.0); });
    time_group("g8_misaligned", noop_setup,
               [&] { s8m = g8_misaligned_sum(g_da + 1, N); },
               [&] { return static_cast<long>(s8m * 1000.0); });

    // G9 展开干预
    long s9a = 0, s9b = 0;
    time_group("g9_isum_plain", noop_setup,
               [&] { s9a = g9_isum_plain(g_la, N); }, [&] { return s9a; });
    time_group("g9_isum_unroll", noop_setup,
               [&] { s9b = g9_isum_unroll(g_la, N); }, [&] { return s9b; });

    return 0;
}
