// arena / bump allocator 与裸 new/delete 对照基准
//
// 两组负载：
//   ST  单线程批量建/批量毁：100 万个变长对象，尺寸 32/128/256 字节三档，
//       对象全部保留到批次末尾再统一销毁；arena 用一次 reset 代替 100 万次 delete。
//   MT  多线程争用：1/2/4/8 线程，每线程 20 万个 32 字节对象，
//       三种形态：raw-batch 每线程独立 new 后统一 delete（无跨线程共享），
//       arena-per-thread 每线程独立 arena（无共享即无锁），
//       arena-shared 全部线程共用一个带互斥锁的 arena（分配点串行化）。
//
// 计时 std::chrono::steady_clock，进程内 5 轮取中位；外层 run.sh 跑 7 次再取中位。
// 堆分配次数由重载的全局 operator new/delete 统计（含对齐版）。
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <new>
#include <thread>
#include <vector>

// ---------------- 全局 operator new/delete 计数 ----------------

static std::atomic<std::size_t> g_new_calls{0};
static std::atomic<std::size_t> g_new_bytes{0};
static std::atomic<std::size_t> g_delete_calls{0};

static void count_alloc(std::size_t n) {
    g_new_calls.fetch_add(1, std::memory_order_relaxed);
    g_new_bytes.fetch_add(n, std::memory_order_relaxed);
}
static void count_free() { g_delete_calls.fetch_add(1, std::memory_order_relaxed); }

void* operator new(std::size_t n) {
    count_alloc(n);
    if (void* p = std::malloc(n)) return p;
    throw std::bad_alloc();
}
void operator delete(void* p) noexcept { count_free(); std::free(p); }
void* operator new[](std::size_t n) {
    count_alloc(n);
    if (void* p = std::malloc(n)) return p;
    throw std::bad_alloc();
}
void operator delete[](void* p) noexcept { count_free(); std::free(p); }
void* operator new(std::size_t n, std::align_val_t a) {
    count_alloc(n);
    void* p = nullptr;
    if (posix_memalign(&p, static_cast<std::size_t>(a), n) != 0)
        throw std::bad_alloc();
    return p;
}
void operator delete(void* p, std::align_val_t) noexcept { count_free(); std::free(p); }
void operator delete(void* p, std::size_t) noexcept { count_free(); std::free(p); }
void operator delete[](void* p, std::size_t) noexcept { count_free(); std::free(p); }
void* operator new[](std::size_t n, std::align_val_t a) {
    count_alloc(n);
    void* p = nullptr;
    if (posix_memalign(&p, static_cast<std::size_t>(a), n) != 0)
        throw std::bad_alloc();
    return p;
}
void operator delete[](void* p, std::align_val_t) noexcept { count_free(); std::free(p); }
void operator delete(void* p, std::size_t, std::align_val_t) noexcept {
    count_free();
    std::free(p);
}
void operator delete[](void* p, std::size_t, std::align_val_t) noexcept {
    count_free();
    std::free(p);
}

// 逃逸屏障：强制分配结果被真实使用，阻止编译器消除 new/delete 对
static inline void escape_barrier(const void* p) {
    asm volatile("" : : "r"(p) : "memory");
}

// ---------------- Arena：大块预留 + 指针碰撞分配 + 整批 reset ----------------

class Arena {
public:
    explicit Arena(std::size_t capacity)
        : base_(static_cast<unsigned char*>(::operator new(capacity))),
          cur_(base_),
          end_(base_ + capacity) {}
    Arena(const Arena&) = delete;
    Arena& operator=(const Arena&) = delete;
    ~Arena() { ::operator delete(base_); }

    void* allocate(std::size_t size, std::size_t alignment = 16) {
        std::uintptr_t p = reinterpret_cast<std::uintptr_t>(cur_);
        p = (p + alignment - 1) & ~(alignment - 1);
        if (p + size > reinterpret_cast<std::uintptr_t>(end_)) return nullptr;
        cur_ = reinterpret_cast<unsigned char*>(p + size);
        return reinterpret_cast<void*>(p);
    }
    // 整批回收：不触碰任何已分配对象，仅回卷指针，O(1)
    void reset() noexcept { cur_ = base_; }
    std::size_t used() const noexcept { return cur_ - base_; }

private:
    unsigned char* base_;
    unsigned char* cur_;
    unsigned char* end_;
};

class LockedArena {
public:
    explicit LockedArena(std::size_t capacity) : arena_(capacity) {}
    void* allocate(std::size_t size, std::size_t alignment = 16) {
        std::lock_guard<std::mutex> lock(mu_);
        return arena_.allocate(size, alignment);
    }
private:
    std::mutex mu_;
    Arena arena_;
};

// ---------------- 负载与计时工具 ----------------

static std::uint64_t g_sink = 0;
static inline std::uint64_t touch(void* p, std::size_t n) {
    unsigned char* b = static_cast<unsigned char*>(p);
    for (std::size_t i = 0; i < n; i += 16) b[i] = static_cast<unsigned char>(i);
    b[n - 1] = 0x5a;  // 保证末字节被真实写入，sink 不会恒为 0
    return b[0] + b[n - 1];
}
static double median(std::vector<double> v) {
    std::sort(v.begin(), v.end());
    return v[v.size() / 2];
}
using Clock = std::chrono::steady_clock;
static double elapsed_ns(Clock::time_point a, Clock::time_point b) {
    return std::chrono::duration<double, std::nano>(b - a).count();
}

// ---------------- ST：单线程批量建 / 批量毁 ----------------

static constexpr std::size_t ST_N = 1000000;
static constexpr std::size_t ST_SIZES[3] = {32, 128, 256};
static constexpr std::size_t ST_ARENA_CAP = 512ull << 20;  // 512MB，容纳 256B 档

template <bool UseArena>
static double st_once(std::size_t size) {
    Arena* arena = nullptr;
    if (UseArena) arena = new Arena(ST_ARENA_CAP);
    std::vector<void*> ptrs(ST_N);
    auto t0 = Clock::now();
    for (std::size_t i = 0; i < ST_N; ++i) {
        void* p = UseArena ? arena->allocate(size)
                           : static_cast<void*>(::operator new(size));
        if (!p) { std::fprintf(stderr, "arena exhausted\n"); std::abort(); }
        g_sink += touch(p, size);
        ptrs[i] = p;
        escape_barrier(p);
    }
    if (UseArena) arena->reset();
    else for (void* p : ptrs) ::operator delete(p);
    auto t1 = Clock::now();
    delete arena;
    return elapsed_ns(t0, t1) / ST_N;
}

static void run_st(const char* opt) {
    std::printf("== ST %s 单线程批量建/毁，N=%zu，5 轮取中位 ==\n", opt, ST_N);
    for (std::size_t size : ST_SIZES) {
        std::vector<double> raw(5), arena(5);
        for (int r = 0; r < 5; ++r) raw[r] = st_once<false>(size);
        for (int r = 0; r < 5; ++r) arena[r] = st_once<true>(size);
        double mr = median(raw), ma = median(arena);
        std::printf("[ST|%zuB|raw]   中位 %7.2f ns/对象  样本 %.2f %.2f %.2f %.2f %.2f\n",
                    size, mr, raw[0], raw[1], raw[2], raw[3], raw[4]);
        std::printf("[ST|%zuB|arena] 中位 %7.2f ns/对象  样本 %.2f %.2f %.2f %.2f %.2f\n",
                    size, ma, arena[0], arena[1], arena[2], arena[3], arena[4]);
    }
}

// ---------------- MT：多线程争用 ----------------

static constexpr std::size_t MT_PER_THREAD = 200000;
static constexpr std::size_t MT_SIZE = 32;
static constexpr std::size_t MT_SHARED_CAP = 128ull << 20;
static constexpr std::size_t MT_LOCAL_CAP = 16ull << 20;

enum MtKind { MT_RAW, MT_LOCAL_ARENA, MT_SHARED_ARENA };

static void mt_worker(MtKind kind, LockedArena* shared) {
    if (kind == MT_SHARED_ARENA) {
        for (std::size_t i = 0; i < MT_PER_THREAD; ++i) {
            void* p = shared->allocate(MT_SIZE);
            if (!p) { std::fprintf(stderr, "shared arena exhausted\n"); std::abort(); }
            g_sink += touch(p, MT_SIZE);
            escape_barrier(p);
        }
        return;
    }
    if (kind == MT_LOCAL_ARENA) {
        Arena arena(MT_LOCAL_CAP);
        for (std::size_t i = 0; i < MT_PER_THREAD; ++i) {
            void* p = arena.allocate(MT_SIZE);
            g_sink += touch(p, MT_SIZE);
            escape_barrier(p);
        }
        return;
    }
    std::vector<void*> ptrs(MT_PER_THREAD);
    for (std::size_t i = 0; i < MT_PER_THREAD; ++i) {
        void* p = ::operator new(MT_SIZE);
        g_sink += touch(p, MT_SIZE);
        ptrs[i] = p;
        escape_barrier(p);
    }
    for (void* p : ptrs) ::operator delete(p);
}

static double mt_once(MtKind kind, int threads) {
    LockedArena shared(MT_SHARED_CAP);
    auto t0 = Clock::now();
    std::vector<std::thread> pool;
    pool.reserve(threads);
    for (int i = 0; i < threads; ++i) pool.emplace_back(mt_worker, kind, &shared);
    for (auto& t : pool) t.join();
    auto t1 = Clock::now();
    return elapsed_ns(t0, t1);
}

static void run_mt(const char* opt) {
    static const int kThreads[4] = {1, 2, 4, 8};
    static const char* kNames[3] = {"raw-batch", "arena-thread", "arena-shared"};
    std::printf("== MT %s 多线程争用，每线程 %zu 个 %zuB 对象，5 轮取中位 ==\n",
                opt, MT_PER_THREAD, MT_SIZE);
    for (int t : kThreads) {
        double total = static_cast<double>(t) * MT_PER_THREAD;
        for (int k = 0; k < 3; ++k) {
            std::vector<double> samples(5);
            for (int r = 0; r < 5; ++r) samples[r] = mt_once(static_cast<MtKind>(k), t);
            double m = median(samples);
            std::printf("[MT|%dt|%s] 总 %8.3f ms  %6.2f ns/对象  吞吐 %8.2f M对象/s\n",
                        t, kNames[k], m / 1e6, m / total, total / m * 1000.0);
        }
    }
}

// ---------------- 单轮分配计数 delta：把「省了多少次堆分配」数出来 ----------------

struct Counters {
    std::size_t calls, bytes, frees;
    static Counters now() {
        return {g_new_calls.load(), g_new_bytes.load(), g_delete_calls.load()};
    }
    Counters operator-(const Counters& o) const {
        return {calls - o.calls, bytes - o.bytes, frees - o.frees};
    }
};

static void run_counts() {
    std::printf("== 单轮分配计数 delta（ST 取 32B 档，MT 取 4 线程）==\n");
    Counters a, b;

    a = Counters::now();
    {
        std::vector<void*> ptrs(ST_N);
        for (std::size_t i = 0; i < ST_N; ++i) {
            void* p = ::operator new(32);
            g_sink += touch(p, 32);
            ptrs[i] = p;
        }
        for (void* p : ptrs) ::operator delete(p);
    }
    b = Counters::now();
    Counters d1 = b - a;
    std::printf("[count|ST-32B-raw]   new=%zu 次/%zu 字节  delete=%zu 次\n",
                d1.calls, d1.bytes, d1.frees);

    a = Counters::now();
    {
        Arena arena(ST_ARENA_CAP);
        for (std::size_t i = 0; i < ST_N; ++i) {
            void* p = arena.allocate(32);
            g_sink += touch(p, 32);
            escape_barrier(p);
        }
        arena.reset();
    }
    b = Counters::now();
    Counters d2 = b - a;
    std::printf("[count|ST-32B-arena] new=%zu 次/%zu 字节  delete=%zu 次（reset 不进分配器）\n",
                d2.calls, d2.bytes, d2.frees);

    auto mt_count = [](MtKind kind, int threads) {
        Counters x = Counters::now();
        LockedArena shared(MT_SHARED_CAP);
        std::vector<std::thread> pool;
        for (int i = 0; i < threads; ++i) pool.emplace_back(mt_worker, kind, &shared);
        for (auto& t : pool) t.join();
        Counters y = Counters::now();
        Counters d = y - x;
        std::printf("[count|MT-4t-%s] new=%zu 次/%zu 字节  delete=%zu 次\n",
                    kind == MT_RAW ? "raw-batch"
                    : kind == MT_LOCAL_ARENA ? "arena-thread" : "arena-shared",
                    d.calls, d.bytes, d.frees);
    };
    mt_count(MT_RAW, 4);
    mt_count(MT_LOCAL_ARENA, 4);
    mt_count(MT_SHARED_ARENA, 4);
}

int main(int argc, char** argv) {
    const char* opt = (argc > 1) ? argv[1] : "O2";
    run_st(opt);
    run_mt(opt);
    run_counts();
    std::printf("== 全程累计（含 5 轮 × 各档重复）==\n");
    std::printf("operator new 调用 %zu 次，累计 %zu 字节，delete %zu 次\n",
                g_new_calls.load(), g_new_bytes.load(), g_delete_calls.load());
    std::printf("sink %llu\n", static_cast<unsigned long long>(g_sink));
    return 0;
}
