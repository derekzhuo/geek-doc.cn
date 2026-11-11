#include <chrono>
#include <cstdio>
#include <cstdlib>
#include "types.hpp"
#include "factory.hpp"

// 五种调用形态 + 一个静态分派基线，每个形态独占函数，
// 便于用 otool 按函数名截取反汇编、逐条核对间接调用是否被消除。
constexpr long ITERATIONS = 100'000'000L;

using Clock = std::chrono::steady_clock;

static double elapsed_ms(Clock::time_point t0, Clock::time_point t1) {
    return std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count()
           / 1000.0;
}

// F0 静态分派基线：对象具体类型在编译期已知，根本不经过虚表。
__attribute__((noinline))
std::int64_t run_direct(long iters) {
    OpenDerived d;
    std::int64_t x = 20261111;
    for (long i = 0; i < iters; ++i) x = d.step(x);
    return x;
}

// F1 堆上开放类：无 final，构造点虽在本 TU，但指针类型擦除为 Base*。
__attribute__((noinline))
std::int64_t run_heap_open(long iters) {
    Base* p = new OpenDerived();
    std::int64_t x = 20261111;
    for (long i = 0; i < iters; ++i) x = p->step(x);
    delete p;
    return x;
}

// F2 堆上 final 类：继承链封闭，编译器可经 final 证明虚表唯一。
__attribute__((noinline))
std::int64_t run_heap_final(long iters) {
    Base* p = new Derived();
    std::int64_t x = 20261111;
    for (long i = 0; i < iters; ++i) x = p->step(x);
    delete p;
    return x;
}

// F3 可见局部对象：构造点就在眼前，动态类型可直接观察，即使类无 final。
__attribute__((noinline))
std::int64_t run_visible_local(long iters) {
    OpenDerived d;
    Base* p = &d;
    std::int64_t x = 20261111;
    for (long i = 0; i < iters; ++i) x = p->step(x);
    return x;
}

// F4 跨翻译单元工厂：真实类型藏在另一个 TU 的 new 里，单 TU 编译完全不可见。
__attribute__((noinline))
std::int64_t run_cross_tu(long iters) {
    Base* p = makeOpen();
    std::int64_t x = 20261111;
    for (long i = 0; i < iters; ++i) x = p->step(x);
    delete p;
    return x;
}

int main(int argc, char** argv) {
    const char* mode = argc > 1 ? argv[1] : "run";
    struct Case {
        const char* name;
        std::int64_t (*fn)(long);
    };
    const Case cases[] = {
        {"direct",        run_direct},
        {"heap_open",     run_heap_open},
        {"heap_final",    run_heap_final},
        {"visible_local", run_visible_local},
        {"cross_tu",      run_cross_tu},
    };

    for (const Case& c : cases) {
        c.fn(ITERATIONS / 100);  // 预热
        const auto t0 = Clock::now();
        const std::int64_t checksum = c.fn(ITERATIONS);
        const auto t1 = Clock::now();
        std::printf("mode=%s form=%-13s elapsed_ms=%8.3f checksum=%lld\n",
                    mode, c.name, elapsed_ms(t0, t1),
                    static_cast<long long>(checksum));
    }
    return 0;
}
