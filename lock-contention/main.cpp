// main.cpp —— 锁争用分析实验
//
// 4 线程争用 3 种锁：
//   1. std::mutex + 短临界区 — 轻争用，锁很快释放
//   2. std::mutex + 长临界区 — 重争用，持锁时间长
//   3. pthread_spinlock + 极短临界区 — spinlock 适用场景
//
// 用 perf lock record → perf lock report 看每把锁的：
//   - contended (争用次数)
//   - wait-time (总等待时间)
//   - max-wait-time (最长单次等待)
//   - average-wait-time (平均等待)
//
// 编译: make          → -O2 -std=c++17 -lpthread
//
// 用法:
//   ./lock_contention 10       → 跑 10 秒（默认）
//
// perf 示例:
//   # 录制锁事件
//   perf lock record -a ./lock_contention 10
//   # 分析报告
//   perf lock report
//   # 查看持有者的调用栈
//   perf lock report -k

#include <iostream>
#include <thread>
#include <mutex>
#include <atomic>
#include <chrono>
#include <vector>
#include <pthread.h>
#include <unistd.h>

// ── 锁封装：方便在多个锁之间切换 ─────────────────────────────
struct MutexLock {
    std::mutex mtx;
    void lock()   { mtx.lock(); }
    void unlock() { mtx.unlock(); }
};

struct SpinLock {
    pthread_spinlock_t spin;
    SpinLock()  { pthread_spin_init(&spin, PTHREAD_PROCESS_PRIVATE); }
    ~SpinLock() { pthread_spin_destroy(&spin); }
    void lock()   { pthread_spin_lock(&spin); }
    void unlock() { pthread_spin_unlock(&spin); }
};

// ── 短临界区 worker ─────────────────────────────────────────
template<typename Lock>
void worker_short(Lock& lk, int id, int seconds, std::atomic<bool>& stop,
                  std::atomic<long>& ops) {
    while (!stop.load(std::memory_order_relaxed)) {
        lk.lock();
        ops.fetch_add(1, std::memory_order_relaxed);  // 极短临界区
        lk.unlock();
    }
}

// ── 长临界区 worker ──────────────────────────────────────────
template<typename Lock>
void worker_long(Lock& lk, int id, int seconds, std::atomic<bool>& stop,
                 std::atomic<long>& ops) {
    while (!stop.load(std::memory_order_relaxed)) {
        lk.lock();
        ops.fetch_add(1, std::memory_order_relaxed);
        // 模拟长临界区：做一段计算
        volatile int x = 0;
        for (int i = 0; i < 100; i++) x += i;
        (void)x;
        lk.unlock();
    }
}

// ── 运行一组测试 ────────────────────────────────────────────
template<typename Lock>
void run_test(const char* name, Lock& lk, int seconds, bool long_critical) {
    std::atomic<long> ops{0};
    std::atomic<bool> stop{false};
    const int NTHREADS = 8;

    std::vector<std::thread> threads;
    for (int i = 0; i < NTHREADS; i++) {
        if (long_critical)
            threads.emplace_back(worker_long<Lock>, std::ref(lk),
                                 i, seconds, std::ref(stop), std::ref(ops));
        else
            threads.emplace_back(worker_short<Lock>, std::ref(lk),
                                 i, seconds, std::ref(stop), std::ref(ops));
    }

    std::this_thread::sleep_for(std::chrono::seconds(seconds));
    stop.store(true);

    for (auto& t : threads) t.join();

    std::cout << "  [" << name << "] " << NTHREADS << "线程, "
              << ops.load() << " ops, "
              << (ops.load() / seconds) << " ops/s" << std::endl;
}

int main(int argc, char** argv) {
    int test_sec = 10;
    if (argc >= 2) test_sec = std::atoi(argv[1]);
    if (test_sec < 2) test_sec = 2;
    if (test_sec > 60) test_sec = 60;

    std::cout << "\n╔══════════════════════════════════════════════════════════╗\n"
              << "║       锁争用分析实验 (perf lock demo)                      ║\n"
              << "║   每组 " << test_sec << " 秒, 8 线程                                         ║\n"
              << "╚══════════════════════════════════════════════════════════╝\n\n";

    // 1) mutex + 短临界区
    {
        MutexLock lk;
        run_test("mutex 短临界区", lk, test_sec, false);
    }

    // 2) mutex + 长临界区
    {
        MutexLock lk;
        run_test("mutex 长临界区", lk, test_sec, true);
    }

    // 3) spinlock + 短临界区
    {
        SpinLock lk;
        run_test("spinlock 短临界区", lk, test_sec, false);
    }

    std::cout << "\n── perf 建议命令 ──\n\n"
              << "  # 第一步: 录制锁事件 (需要 root, 内核需开启 CONFIG_LOCKDEP)\n"
              << "  sudo perf lock record -a ./lock_contention " << test_sec << "\n\n"
              << "  # 第二步: 分析报告\n"
              << "  perf lock report\n\n"
              << "  # 第三步: 看持有者的调用栈\n"
              << "  perf lock report -k\n\n"
              << "  # syscall 视角看 futex 调用量\n"
              << "  perf stat -e 'syscalls:sys_enter_futex' -a sleep " << test_sec << "\n\n"
              << "── 预期观察 ──\n\n"
              << "   ▸ mutex 短临界区: 争用次数多但每把锁等待时间短\n"
              << "   ▸ mutex 长临界区: 总等待时间 / 最大等待时间 都高，最差的锁等几十 ms\n"
              << "   ▸ spinlock: 在短临界区场景下 wait-time 很低，因为没有 futex 睡眠/唤醒开销\n\n"
              << "  注意: 若内核未开启 CONFIG_LOCKDEP，perf lock 可能无法录制锁事件。\n"
              << "  届时可用 perf trace 的 futex 计数做近似分析。\n";

    return 0;
}
