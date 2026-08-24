// reorder_demo.cpp
// 演示普通共享变量的 data-race UB(编译器重排/寄存器缓存/删循环),以及 std::atomic 的正确修复。
// 对应文档: tools/cache/compiler-reordering.md 第六节。
//
//   普通变量版(错误): 编译 demo_plain   → 可能死循环(表现A) 或 秒退且顺序颠倒(表现B)
//   原子变量版(正确): 编译 demo_atomic  → main 先 setting, waiter 才 saw, 顺序永远对
//
// 用宏 USE_ATOMIC 切换两版; 详见同目录 Makefile / README.md。
#include <atomic>
#include <chrono>
#include <cstdio>
#include <thread>

#ifdef USE_ATOMIC
std::atomic<bool> flag{false};   // 正确:编译器不缓存进寄存器 + 带 acquire/release 语义
inline bool read_flag()  { return flag.load(std::memory_order_acquire); }
inline void write_flag() { flag.store(true, std::memory_order_release); }
#else
bool flag = false;               // 错误:普通变量,-O2 下 data race = UB
inline bool read_flag()  { return flag; }
inline void write_flag() { flag = true; }
#endif

int main() {
    std::thread waiter([] {
        std::puts("waiter: spinning on flag...");
        while (!read_flag()) {
            // 空循环体:编译器认定这里没人改 flag
            //  -O2 普通变量版 → 把 load 提出循环(表现A 死循环)或整段删除(表现B 秒退)
        }
        std::puts("waiter: saw flag=true, exiting");
    });

    std::this_thread::sleep_for(std::chrono::seconds(1));
    std::puts("main:   setting flag=true");
    write_flag();

    waiter.join();
    std::puts("main:   joined, done");
    return 0;
}
