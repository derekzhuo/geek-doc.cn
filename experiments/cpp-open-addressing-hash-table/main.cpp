// 开寻址（线性探测）哈希表 vs std::unordered_map（开链）基准
// 负载因子 0.3..0.9 七档扫档：探测长度、成功/不成功查找耗时、插入耗时、每条目内存
#include <algorithm>
#include <cassert>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <new>
#include <random>
#include <unordered_map>
#include <vector>

// ---------- 全局 operator new 计数：统计 unordered_map 存活堆字节 ----------
static bool g_counting = false;
static long g_live_bytes = 0;
static long g_alloc_calls = 0;

static void* track_new(std::size_t n) {
    void* p = std::malloc(n);
    if (!p) throw std::bad_alloc();
    if (g_counting) {
        g_live_bytes += static_cast<long>(n);
        ++g_alloc_calls;
    }
    return p;
}
static void track_del(void* p) noexcept {
    // 简化口径：配对释放由程序生命周期保证，存活字节只在构造区间读数，
    // 析构发生在计数关闭之后，与同系列其他实验口径一致。
    std::free(p);
}

void* operator new(std::size_t n) { return track_new(n); }
void* operator new[](std::size_t n) { return track_new(n); }
void* operator new(std::size_t n, std::align_val_t) { return track_new(n); }
void* operator new[](std::size_t n, std::align_val_t) { return track_new(n); }
void operator delete(void* p) noexcept { track_del(p); }
void operator delete[](void* p) noexcept { track_del(p); }
void operator delete(void* p, std::size_t) noexcept { track_del(p); }
void operator delete[](void* p, std::size_t) noexcept { track_del(p); }
void operator delete(void* p, std::align_val_t) noexcept { track_del(p); }
void operator delete[](void* p, std::align_val_t) noexcept { track_del(p); }

// ---------- 开寻址哈希表：线性探测 + backward-shift 删除 ----------
struct Slot {
    int key;
    int value;
    bool used;
};

class OpenAddressTable {
public:
    explicit OpenAddressTable(std::size_t cap)
        : cap_(cap), mask_(cap - 1), slots_(cap) {
        // 容量必须是 2 的幂，靠掩码代替取模
        assert((cap & (cap - 1)) == 0);
    }

    std::size_t capacity() const { return cap_; }
    std::size_t size() const { return size_; }
    std::size_t slot_bytes() const { return sizeof(Slot); }

    // 插入；返回本次插入经历的探测步数（首槽即空为 1）
    std::size_t insert(int key, int value) {
        std::size_t idx = hash(key) & mask_;
        std::size_t probes = 0;
        while (true) {
            ++probes;
            Slot& s = slots_[idx];
            if (!s.used) {
                s = {key, value, true};
                ++size_;
                return probes;
            }
            if (s.key == key) {
                s.value = value;
                return probes;
            }
            idx = (idx + 1) & mask_;
        }
    }

    // 查找；命中返回探测步数，未命中返回遇到空槽为止的探测步数
    std::size_t lookup_probes(int key, bool& hit) const {
        std::size_t idx = hash(key) & mask_;
        std::size_t probes = 0;
        while (true) {
            ++probes;
            const Slot& s = slots_[idx];
            if (!s.used) {
                hit = false;
                return probes;
            }
            if (s.key == key) {
                hit = true;
                return probes;
            }
            idx = (idx + 1) & mask_;
        }
    }

    // backward-shift 删除：删掉条目后沿探测簇向后回挪，不留墓碑
    void erase(int key) {
        std::size_t idx = hash(key) & mask_;
        while (slots_[idx].used && slots_[idx].key != key)
            idx = (idx + 1) & mask_;
        if (!slots_[idx].used) return;

        slots_[idx].used = false;
        --size_;
        std::size_t hole = idx;
        std::size_t j = (hole + 1) & mask_;
        while (slots_[j].used) {
            std::size_t home = hash(slots_[j].key) & mask_;
            // 若 j 的家槽不在 (hole, j] 这个循环区间内，回挪可以补上洞
            if (!in_cycle(home, hole, j)) {
                slots_[hole] = slots_[j];
                slots_[j].used = false;
                hole = j;
            }
            j = (j + 1) & mask_;
        }
    }

private:
    // 判断 pos 是否落在开区间 (left, right]（按环形下标递增方向）
    static bool in_cycle(std::size_t pos, std::size_t left, std::size_t right) {
        if (left < right) return pos > left && pos <= right;
        return pos > left || pos <= right;
    }
    static std::size_t hash(int key) {
        return static_cast<std::size_t>(static_cast<std::uint32_t>(key)) * 2654435761u;
    }

    std::size_t cap_;
    std::size_t mask_;
    std::size_t size_ = 0;
    std::vector<Slot> slots_;
};

using Clock = std::chrono::steady_clock;

static double now_ns() {
    return std::chrono::duration<double, std::nano>(
               Clock::now().time_since_epoch())
        .count();
}

// 内部 3 次取最短，外层 run.sh 再做 7 次中位
template <class F>
static double best_of_3(F&& f) {
    double best = 1e18;
    for (int r = 0; r < 3; ++r) {
        double t0 = now_ns();
        f();
        double t1 = now_ns();
        best = std::min(best, t1 - t0);
    }
    return best;
}

int main() {
    constexpr std::size_t CAP = 1u << 18; // 262144 槽，全档共用
    constexpr std::size_t Q = 200'000;     // 每次计时的操作数
    const double alphas[] = {0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9};

    // 固定种子，保证两种结构面对完全相同的 key 序列
    // key 池是容量的 4 倍区间，不同 key 的家槽才会自然碰撞；
    // 不能取 [0,CAP) 全集——奇数乘法散列对 2 的幂模是双射，全集键零碰撞
    std::mt19937 rng(20261112u);
    const int KEY_RANGE = static_cast<int>(CAP) * 4;
    std::vector<int> pool(KEY_RANGE);
    for (int i = 0; i < KEY_RANGE; ++i) pool[i] = i;
    std::shuffle(pool.begin(), pool.end(), rng);

    // 缺失 key 取自另一区间，保证不在表内且哈希分布一致
    std::vector<int> missing(Q);
    std::uniform_int_distribution<int> miss_dist(KEY_RANGE, KEY_RANGE * 4);
    for (auto& k : missing) k = miss_dist(rng);

    std::puts("# 开寻址线性探测 vs std::unordered_map 负载因子扫档");
    std::puts("# CAP=262144 固定，N=round(alpha*CAP)，计时内部 3 次取最短");

    // ---------- 正确性自检：backward-shift 删除后探测链不断 ----------
    {
        OpenAddressTable t(64);
        for (int i = 0; i < 40; ++i) t.insert(i * 7 + 3, i);
        for (int i = 0; i < 20; ++i) t.erase(i * 7 + 3);
        bool ok = true;
        for (int i = 20; i < 40; ++i) {
            bool hit = false;
            t.lookup_probes(i * 7 + 3, hit);
            ok = ok && hit;
        }
        for (int i = 0; i < 20; ++i) {
            bool hit = true;
            t.lookup_probes(i * 7 + 3, hit);
            ok = ok && !hit;
        }
        std::printf("自检 backward-shift 删除后存活键全命中、已删键全未命中: %s\n",
                    ok ? "PASS" : "FAIL");
    }

    volatile long sink = 0;

    for (double alpha : alphas) {
        std::size_t n = static_cast<std::size_t>(alpha * CAP + 0.5);
        double real_alpha = static_cast<double>(n) / CAP;
        std::vector<int> keys(pool.begin(), pool.begin() + n);

        std::printf("\nalpha=%.1f N=%zu CAP=%zu 实际负载因子=%.4f\n",
                    alpha, n, CAP, real_alpha);

        // ----- 开寻址表：探测长度统计 -----
        OpenAddressTable oa(CAP);
        for (int k : keys) oa.insert(k, k * 2);

        long hit_probe_sum = 0;
        for (int k : keys) {
            bool hit = false;
            hit_probe_sum += static_cast<long>(oa.lookup_probes(k, hit));
            assert(hit);
        }
        long miss_probe_sum = 0;
        for (int k : missing) {
            bool hit = true;
            miss_probe_sum += static_cast<long>(oa.lookup_probes(k, hit));
            assert(!hit);
        }
        double hit_pl = static_cast<double>(hit_probe_sum) / n;
        double miss_pl = static_cast<double>(miss_probe_sum) / Q;
        std::printf("  OA 成功平均探测长度=%.3f 不成功平均探测长度=%.3f\n",
                    hit_pl, miss_pl);

        // ----- 计时：成功查找 / 不成功查找 / 插入 -----
        double oa_hit = best_of_3([&] {
            long acc = 0;
            for (std::size_t i = 0; i < Q; ++i) {
                bool hit;
                acc += static_cast<long>(oa.lookup_probes(keys[i % n], hit));
            }
            sink += acc;
        }) / Q;
        double oa_miss = best_of_3([&] {
            long acc = 0;
            for (int k : missing) {
                bool hit;
                acc += static_cast<long>(oa.lookup_probes(k, hit));
            }
            sink += acc;
        }) / Q;
        double oa_insert = best_of_3([&] {
            OpenAddressTable fresh(CAP);
            for (int k : keys) fresh.insert(k, k * 2);
            sink += static_cast<long>(fresh.size());
        }) / n;

        // ----- unordered_map 对照 -----
        g_counting = true;
        g_live_bytes = 0;
        g_alloc_calls = 0;
        std::unordered_map<int, int> um;
        um.reserve(n);
        for (int k : keys) um.emplace(k, k * 2);
        long um_bytes = g_live_bytes;
        long um_allocs = g_alloc_calls;
        g_counting = false;

        double um_hit = best_of_3([&] {
            long acc = 0;
            for (std::size_t i = 0; i < Q; ++i)
                acc += um.find(keys[i % n])->second;
            sink += acc;
        }) / Q;
        double um_miss = best_of_3([&] {
            long acc = 0;
            for (int k : missing) acc += (um.find(k) == um.end());
            sink += acc;
        }) / Q;
        double um_insert = best_of_3([&] {
            std::unordered_map<int, int> fresh;
            fresh.reserve(n);
            for (int k : keys) fresh.emplace(k, k * 2);
            sink += static_cast<long>(fresh.size());
        }) / n;

        // 每行只放一个测量值，标签带整数 N 保证跨负载因子唯一（供外层中位脚本聚合）
        std::printf("  [N=%zu] OA 成功查找=%.2f ns/次\n", n, oa_hit);
        std::printf("  [N=%zu] OA 不成功查找=%.2f ns/次\n", n, oa_miss);
        std::printf("  [N=%zu] OA 插入=%.2f ns/次\n", n, oa_insert);
        std::printf("  [N=%zu] UM 成功查找=%.2f ns/次\n", n, um_hit);
        std::printf("  [N=%zu] UM 不成功查找=%.2f ns/次\n", n, um_miss);
        std::printf("  [N=%zu] UM 插入=%.2f ns/次\n", n, um_insert);

        double oa_per = static_cast<double>(CAP * sizeof(Slot)) / n;
        double um_per = static_cast<double>(um_bytes) / n;
        std::printf("  OA 每条目=%.2f B（slot=%zu B × %zu 槽 / %zu 元素）\n",
                    oa_per, sizeof(Slot), CAP, n);
        std::printf("  UM 每条目=%.2f B（new 存活 %ld B / %zu，分配 %ld 次）\n",
                    um_per, um_bytes, n, um_allocs);
    }

    std::printf("\n校验和=%ld\n", static_cast<long>(sink));
    return 0;
}
