// 三种查找结构对照基准：std::map / std::unordered_map / 排序 vector + lower_bound
// 元素量 8 .. 1M 扫档，每档 10 万次随机命中查找，结构内三次重复取最短耗时。
// 另统计构造期堆分配（重载 operator new）得到每条目实际占用字节。
#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <map>
#include <random>
#include <unordered_map>
#include <utility>
#include <vector>

// ---------- 全局 operator new 计数 ----------
static bool g_counting = false;
static uint64_t g_alloc_count = 0;   // 构造期 new 次数（毛额）
static uint64_t g_alloc_bytes = 0;   // 构造期 new 字节（毛额）
static uint64_t g_live_bytes = 0;    // 当前仍存活的堆字节（净额）

static inline void track_new(size_t n) {
    if (g_counting) {
        ++g_alloc_count;
        g_alloc_bytes += n;
        g_live_bytes += n;
    }
}
static inline void track_delete(size_t n) {
    if (g_counting) g_live_bytes -= n;
}

void* operator new(size_t n) {
    track_new(n);
    return std::malloc(n);
}
void* operator new[](size_t n) {
    track_new(n);
    return std::malloc(n);
}
void* operator new(size_t n, std::align_val_t) {
    track_new(n);
    return std::malloc(n);
}
void* operator new[](size_t n, std::align_val_t) {
    track_new(n);
    return std::malloc(n);
}
void operator delete(void* p) noexcept { std::free(p); }
void operator delete[](void* p) noexcept { std::free(p); }
void operator delete(void* p, std::align_val_t) noexcept { std::free(p); }
void operator delete[](void* p, std::align_val_t) noexcept { std::free(p); }
void operator delete(void* p, size_t n) noexcept { track_delete(n); std::free(p); }
void operator delete[](void* p, size_t n) noexcept { track_delete(n); std::free(p); }
void operator delete(void* p, size_t n, std::align_val_t) noexcept { track_delete(n); std::free(p); }
void operator delete[](void* p, size_t n, std::align_val_t) noexcept { track_delete(n); std::free(p); }

using Clock = std::chrono::steady_clock;

static double ns_per(const Clock::time_point& t0, const Clock::time_point& t1, uint64_t ops) {
    return std::chrono::duration<double, std::nano>(t1 - t0).count() / static_cast<double>(ops);
}

// 三次内部重复取最小值，降低调度抖动
template <class F>
double best_of_3(F&& f, uint64_t ops) {
    double best = 1e18;
    volatile uint64_t sink = 0;
    for (int r = 0; r < 3; ++r) {
        auto t0 = Clock::now();
        sink += f();
        auto t1 = Clock::now();
        best = std::min(best, ns_per(t0, t1, ops));
    }
    if (sink == 0xdeadbeefULL) std::cerr << "";
    return best;
}

int main() {
    const std::vector<size_t> sizes = {
        8, 16, 32, 64, 128, 256, 512, 1024,
        4096, 16384, 65536, 262144, 1048576};
    const uint64_t LOOKUPS = 100000;
    const std::vector<size_t> mem_sizes = {4096, 1048576};

    std::mt19937 rng(20261112u);
    std::cout.precision(2);
    std::cout << std::fixed;

    std::cout << "# map / unordered_map / sorted-vector 查找基准\n";
    std::cout << "sizeof: map=" << sizeof(std::map<int, int>)
              << "B unordered_map=" << sizeof(std::unordered_map<int, int>)
              << "B vector<pair>=" << sizeof(std::vector<std::pair<int, int>>)
              << "B pair<int,int>=" << sizeof(std::pair<int, int>) << "B\n";
    std::cout << "lookups_per_size=" << LOOKUPS << " 内部 3 次取最短\n\n";

    for (size_t N : sizes) {
        // 生成 N 个互不相同的随机 key：在 [0, 4N) 上洗牌后取前 N 个
        std::vector<int> pool(4 * N);
        for (size_t i = 0; i < pool.size(); ++i) pool[i] = static_cast<int>(i);
        std::shuffle(pool.begin(), pool.end(), rng);
        std::vector<int> keys(pool.begin(), pool.begin() + static_cast<ptrdiff_t>(N));

        // 预生成查找下标（全部命中）
        std::vector<size_t> idx(LOOKUPS);
        std::uniform_int_distribution<size_t> dist(0, N - 1);
        for (uint64_t i = 0; i < LOOKUPS; ++i) idx[i] = dist(rng);

        // ---- 构造/预处理计时与分配计数 ----
        g_counting = true;
        g_alloc_count = 0; g_alloc_bytes = 0; g_live_bytes = 0;
        auto t0 = Clock::now();
        std::map<int, int> m;
        for (int k : keys) m.emplace(k, k * 3);
        auto t1 = Clock::now();
        const uint64_t map_allocs = g_alloc_count;
        const uint64_t map_live = g_live_bytes;
        const double map_prep = ns_per(t0, t1, N);

        g_alloc_count = 0; g_alloc_bytes = 0; g_live_bytes = 0;
        t0 = Clock::now();
        std::unordered_map<int, int> um;
        for (int k : keys) um.emplace(k, k * 3);
        t1 = Clock::now();
        const uint64_t um_allocs = g_alloc_count;
        const uint64_t um_live = g_live_bytes;
        const double um_prep = ns_per(t0, t1, N);

        g_alloc_count = 0; g_alloc_bytes = 0; g_live_bytes = 0;
        t0 = Clock::now();
        std::vector<std::pair<int, int>> sv;
        sv.reserve(N);
        for (int k : keys) sv.emplace_back(k, k * 3);
        std::sort(sv.begin(), sv.end(),
                  [](const auto& a, const auto& b) { return a.first < b.first; });
        t1 = Clock::now();
        const uint64_t sv_allocs = g_alloc_count;
        const uint64_t sv_live = g_live_bytes;
        const double sv_prep = ns_per(t0, t1, N);
        g_counting = false;
        const size_t sv_cap_bytes = sv.capacity() * sizeof(std::pair<int, int>);

        std::cout << "prep   N=" << N << " map " << map_prep << " ns/次\n";
        std::cout << "prep   N=" << N << " unordered_map " << um_prep << " ns/次\n";
        std::cout << "prep   N=" << N << " sorted_vector " << sv_prep << " ns/次\n";

        // ---- 随机命中查找计时 ----
        auto map_lookup = [&]() -> uint64_t {
            uint64_t sum = 0;
            for (size_t i : idx) {
                auto it = m.find(keys[i]);
                sum += static_cast<uint64_t>(it->second);
            }
            return sum;
        };
        auto um_lookup = [&]() -> uint64_t {
            uint64_t sum = 0;
            for (size_t i : idx) {
                auto it = um.find(keys[i]);
                sum += static_cast<uint64_t>(it->second);
            }
            return sum;
        };
        auto sv_lookup = [&]() -> uint64_t {
            uint64_t sum = 0;
            for (size_t i : idx) {
                auto it = std::lower_bound(
                    sv.begin(), sv.end(), keys[i],
                    [](const std::pair<int, int>& e, int v) { return e.first < v; });
                sum += static_cast<uint64_t>(it->second);
            }
            return sum;
        };
        // 预热一轮
        map_lookup(); um_lookup(); sv_lookup();

        std::cout << "lookup N=" << N << " map "
                  << best_of_3(map_lookup, LOOKUPS) << " ns/次\n";
        std::cout << "lookup N=" << N << " unordered_map "
                  << best_of_3(um_lookup, LOOKUPS) << " ns/次\n";
        std::cout << "lookup N=" << N << " sorted_vector "
                  << best_of_3(sv_lookup, LOOKUPS) << " ns/次\n";

        if (std::find(mem_sizes.begin(), mem_sizes.end(), N) != mem_sizes.end()) {
            std::cout << "mem N=" << N << " map allocs=" << map_allocs
                      << " live=" << map_live << "B per="
                      << (map_live / N) << " B/条\n";
            std::cout << "mem N=" << N << " unordered_map allocs=" << um_allocs
                      << " live=" << um_live << "B per="
                      << (um_live / N) << " B/条\n";
            std::cout << "mem N=" << N << " sorted_vector allocs=" << sv_allocs
                      << " live=" << sv_live << "B capacity_bytes="
                      << sv_cap_bytes << " per=" << (sv_cap_bytes / N) << " B/条\n";
        }
        std::cout << "\n";
    }
    return 0;
}
