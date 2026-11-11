#include <chrono>
#include <cstdio>
#include <vector>
#include "work.hpp"

// 工厂函数在各自 worker TU 中以 C 链接定义，main 只经基类指针间接调用。
extern "C" Worker* makeWorker0();
extern "C" Worker* makeWorker1();
extern "C" Worker* makeWorker2();
extern "C" Worker* makeWorker3();
extern "C" Worker* makeWorker4();
extern "C" Worker* makeWorker5();
extern "C" Worker* makeWorker6();
extern "C" Worker* makeWorker7();

int main() {
    std::vector<Worker*> workers{
        makeWorker0(), makeWorker1(), makeWorker2(), makeWorker3(),
        makeWorker4(), makeWorker5(), makeWorker6(), makeWorker7(),
    };

    constexpr int OUTER_ROUNDS = 2000;
    std::int64_t checksum = 0;

    const auto t0 = std::chrono::steady_clock::now();
    for (int round = 0; round < OUTER_ROUNDS; ++round) {
        for (const Worker* w : workers) {
            checksum += w->compute(checksum);
        }
    }
    const auto t1 = std::chrono::steady_clock::now();

    const double ms =
        std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count()
        / 1000.0;
    std::printf("elapsed_ms=%.3f checksum=%lld\n", ms,
                static_cast<long long>(checksum));

    for (Worker* w : workers) delete w;
    return 0;
}
