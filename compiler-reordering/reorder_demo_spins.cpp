// reorder_demo_spins.cpp
// 表现 A 的稳定复现版:给自旋循环加一句有可观测副作用的语句(++spins),
// 让编译器**不敢删循环**(前进保证不再适用),但普通变量下它**仍会把 flag 读进寄存器只读一次**
// → 稳定死循环(spins 一直加、永不退出),要 Ctrl-C。
// 对应文档: tools/cache/compiler-reordering.md 第六节"想稳定复现表现 A 死循环"。
//
//   普通变量版: 编译 spins_plain  → 稳定死循环(见 spins 疯狂增长却不退出),Ctrl-C 终止
//   原子变量版: 编译 spins_atomic → 正确退出,打印实际自旋了多少次
#include <atomic>
#include <chrono>
#include <cstdio>
#include <thread>

#ifdef USE_ATOMIC
std::atomic<bool> flag{false};
inline bool read_flag()  { return flag.load(std::memory_order_acquire); }
inline void write_flag() { flag.store(true, std::memory_order_release); }
#else
bool flag = false;
inline bool read_flag()  { return flag; }
inline void write_flag() { flag = true; }
#endif

int main() {
    std::thread waiter([] {
        std::puts("waiter: spinning on flag (with side effect)...");
        long spins = 0;
        while (!read_flag()) {
            ++spins;                             // 有副作用 → 编译器不能删循环
            asm volatile("" :: "r"(spins) : );   // 阻止把 ++spins 也优化掉
        }
        std::printf("waiter: saw flag=true after %ld spins\n", spins);
    });

    std::this_thread::sleep_for(std::chrono::seconds(1));
    std::puts("main:   setting flag=true");
    write_flag();

    waiter.join();
    std::puts("main:   joined, done");
    return 0;
}
