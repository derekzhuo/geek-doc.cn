#include <chrono>
#include <cstdio>
#include "classifier.hpp"

// 三种负载形态：
//   train   偏斜分布，90% 落在热子树（桶位 192..229），同时是剖面采集负载
//   matched 与训练同分布，验证 PGO 的匹配收益
//   uniform 桶位 0..255 均匀，验证训练/评估分布错位时剖面是否还有用
constexpr long ITERATIONS = 30'000'000;

int main(int argc, char** argv) {
    const char* mode = argc > 1 ? argv[1] : "train";
    long seed = 20261111;
    long checksum = 0;

    const auto t0 = std::chrono::steady_clock::now();
    for (long i = 0; i < ITERATIONS; ++i) {
        // 确定性 LCG，保证三档二进制同模式输入完全一致、checksum 可对拍
        seed = (seed * 1103515245L + 12345L) & 0x7fffffffL;
        long key;
        if (mode[0] == 'u') {            // uniform：0..255 均匀
            key = seed & 255;
        } else if ((seed & 255) < 230) { // 90% 热子树：192..223
            key = 192 + (seed & 31);
        } else {                         // 10% 冷负载：0..255 均匀
            key = seed & 255;
        }
        checksum += classify(key);
    }
    const auto t1 = std::chrono::steady_clock::now();
    const double ms =
        std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count()
        / 1000.0;

    std::printf("mode=%s elapsed_ms=%.3f checksum=%ld\n", mode, ms, checksum);
    return 0;
}
