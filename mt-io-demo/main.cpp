// demos/mt-io-demo/main.cpp
//
// 多线程 + IO 混合程序演示 —— 配合 concepts/tools/perf-multithread-io-analysis.md 的"三步法"使用。
//
// 程序刻意同时提供三类异构线程，便于用 perf/pidstat 实地演练"区分 CPU 型 vs IO 型线程"：
//   1) CPU 型线程：在 user 态密集计算（arith 模式高 IPC / mem 模式低 IPC + cache-miss）
//   2) IO 型线程：阻塞在 nanosleep syscall（模拟 epoll_wait/read 的 IO 等待，voluntary 切换高、%CPU 极低）
//   3) 锁竞争线程：争抢同一把全局 mutex（futex 等待，voluntary 切换高）
//
// 仅 Linux 运行（用 syscall(SYS_gettid) / nanosleep / std::thread + pthread）。
// 编译：g++ -O2 -std=c++17 -pthread -o mt_io_demo main.cpp

#include <iostream>
#include <thread>
#include <vector>
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <unistd.h>
#include <sys/syscall.h>
#include <algorithm>
#include <numeric>
#include <random>
#include <mutex>

static pid_t gettid() { return (pid_t)syscall(SYS_gettid); }

struct Cfg {
    int         cpu_n     = 4;     // CPU 型线程数
    int         cpu_mode  = 0;     // 0 = arith(高 IPC)  1 = mem(低 IPC, cache-miss)
    long long   cpu_iters = 200'000'000LL;
    size_t      mem_bytes = 64 * 1024 * 1024;   // mem 模式工作集（> L3，制造持续 cache miss）
    int         io_n      = 2;     // IO 型线程数
    long        io_us     = 1000;  // 每次"IO 等待"的纳秒睡眠（模拟 IO 间隔）
    int         lock_n    = 2;     // 锁竞争线程数
    long long   lock_iters= 100'000LL;
    int         duration  = 20;    // 运行秒数
};
static Cfg g_cfg;
static std::atomic<bool> g_stop{false};

static void cpu_arith(int id) {
    printf("[tid=%d] CPU#%d (arith 算术, 预期高 IPC) 启动\n", (int)gettid(), id);
    fflush(stdout);
    unsigned long long s = 0;
    while (!g_stop.load(std::memory_order_relaxed)) {
        for (long long i = 0; i < g_cfg.cpu_iters; i++)
            s += (unsigned long long)i * 2654435761u;   // 整数乘法，纯 user 态密集计算
        asm volatile("" : : "r"(s));                    // 防编译器把循环优化掉
    }
}

static void cpu_mem(int id) {
    printf("[tid=%d] CPU#%d (mem 随机访问, 预期低 IPC / cache-miss) 启动\n", (int)gettid(), id);
    fflush(stdout);
    std::vector<unsigned long long> buf(g_cfg.mem_bytes / 8);
    std::vector<size_t> idx(buf.size());
    std::iota(idx.begin(), idx.end(), 0);
    std::mt19937 rng(42);
    std::shuffle(idx.begin(), idx.end(), rng);   // 固定随机访问顺序，每次遍历都持续 LLC miss
    while (!g_stop.load(std::memory_order_relaxed)) {
        volatile unsigned long long sink = 0;
        for (size_t k = 0; k < idx.size(); k++)
            sink += buf[idx[k]];
        (void)sink;
    }
}

static void io_worker(int id) {
    printf("[tid=%d] IO#%d (nanosleep %ldus, 模拟 IO 等待) 启动\n", (int)gettid(), id, g_cfg.io_us);
    fflush(stdout);
    struct timespec req{ g_cfg.io_us / 1000000, (g_cfg.io_us % 1000000) * 1000L };
    while (!g_stop.load(std::memory_order_relaxed)) {
        nanosleep(&req, nullptr);   // 阻塞在 clock_nanosleep syscall —— IO 型线程的典型特征
    }
}

static std::mutex g_lock;
static std::atomic<unsigned long long> g_counter{0};
static void lock_worker(int id) {
    printf("[tid=%d] LOCK#%d (抢全局 mutex) 启动\n", (int)gettid(), id);
    fflush(stdout);
    while (!g_stop.load(std::memory_order_relaxed)) {
        for (long long i = 0; i < g_cfg.lock_iters; i++) {
            std::lock_guard<std::mutex> g(g_lock);
            g_counter.fetch_add(1, std::memory_order_relaxed);
        }
    }
}

static void print_usage() {
    printf("用法: ./mt_io_demo [选项]\n");
    printf("  --cpu N         启动 N 个 CPU 型计算线程 (默认 4)\n");
    printf("  --cpu-mode M     arith(高IPC,默认) | mem(低IPC, 制造 cache-miss 模式A)\n");
    printf("  --cpu-iters N    每轮算术迭代次数 (默认 2e8)\n");
    printf("  --io N           启动 N 个 IO 型线程 (默认 2)\n");
    printf("  --io-us US       每次 IO 等待的微秒数 (默认 1000)\n");
    printf("  --lock N         启动 N 个锁竞争线程 (默认 2)\n");
    printf("  --lock-iters N   每轮加锁次数 (默认 1e5)\n");
    printf("  --duration S     运行秒数 (默认 20)\n");
}

int main(int argc, char** argv) {
    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if (a == "--cpu" && i + 1 < argc)        g_cfg.cpu_n     = atoi(argv[++i]);
        else if (a == "--cpu-mode" && i + 1 < argc) g_cfg.cpu_mode = (std::string(argv[++i]) == "mem") ? 1 : 0;
        else if (a == "--cpu-iters" && i + 1 < argc) g_cfg.cpu_iters = atoll(argv[++i]);
        else if (a == "--io" && i + 1 < argc)    g_cfg.io_n      = atoi(argv[++i]);
        else if (a == "--io-us" && i + 1 < argc) g_cfg.io_us     = atol(argv[++i]);
        else if (a == "--lock" && i + 1 < argc)  g_cfg.lock_n    = atoi(argv[++i]);
        else if (a == "--lock-iters" && i + 1 < argc) g_cfg.lock_iters = atoll(argv[++i]);
        else if (a == "--duration" && i + 1 < argc) g_cfg.duration = atoi(argv[++i]);
        else if (a == "--help" || a == "-h")    { print_usage(); return 0; }
        else { fprintf(stderr, "未知参数: %s\n", a.c_str()); print_usage(); return 1; }
    }

    printf("PID=%d\n", (int)getpid());
    printf("[mt-io-demo] 启动场景: %d CPU(%s) + %d IO + %d LOCK, 运行 %ds\n",
           g_cfg.cpu_n, g_cfg.cpu_mode ? "mem" : "arith",
           g_cfg.io_n, g_cfg.lock_n, g_cfg.duration);
    fflush(stdout);

    std::vector<std::thread> ts;
    for (int i = 0; i < g_cfg.cpu_n;  i++) ts.emplace_back(g_cfg.cpu_mode ? cpu_mem : cpu_arith, i);
    for (int i = 0; i < g_cfg.io_n;   i++) ts.emplace_back(io_worker, i);
    for (int i = 0; i < g_cfg.lock_n; i++) ts.emplace_back(lock_worker, i);

    printf("---- 分析提示（复制到另一个终端）----\n");
    printf("perf stat -p %d -e task-clock,context-switches,cycles:u,cycles:k,instructions:u,instructions:k -- sleep 10\n", (int)getpid());
    printf("pidstat -t -u -w -d -p %d 1\n", (int)getpid());
    printf("perf record -g -F 99 -p %d -- sleep 10\n", (int)getpid());
    printf("perf lock record -p %d -- sleep 5 ; perf lock report\n", (int)getpid());
    printf("strace -c -p %d   # 看 IO 型线程的 nanosleep 占比\n", (int)getpid());
    fflush(stdout);

    std::this_thread::sleep_for(std::chrono::seconds(g_cfg.duration));
    g_stop.store(true, std::memory_order_relaxed);
    for (auto& t : ts) t.join();
    printf("[mt-io-demo] 结束（g_counter=%llu）\n", (unsigned long long)g_counter.load());
    return 0;
}
