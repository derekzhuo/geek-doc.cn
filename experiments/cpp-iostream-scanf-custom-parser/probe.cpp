// 补充探针：把「读字节」与「格式化解析」两件事拆开计时，
// 解释 std::cin 在本平台（macOS + libc++）上的耗时构成。
// 依赖 run.sh 已生成的 data.txt。
#include <chrono>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <string>

using Clock = std::chrono::steady_clock;

static double to_ms(Clock::duration d) {
    return std::chrono::duration<double, std::milli>(d).count();
}

int main() {
    // A：ifstream 流提取，不经过 std::cin 全局流与 stdin 描述符
    {
        std::ifstream f("data.txt");
        long long sum = 0;
        int x = 0;
        auto t0 = Clock::now();
        while (f >> x) sum += x;
        auto t1 = Clock::now();
        std::printf("ifstream >> int  ms=%.1f sum=%lld\n", to_ms(t1 - t0), sum);
    }
    // B：只按行读取不做数字解析，测纯 IO 加拆行成本
    {
        std::ifstream f("data.txt");
        std::string line;
        long long n = 0;
        auto t0 = Clock::now();
        while (std::getline(f, line)) ++n;
        auto t1 = Clock::now();
        std::printf("ifstream getline ms=%.1f lines=%lld\n", to_ms(t1 - t0), n);
    }
    // C：fread 整块搬运，测纯系统读取路径的下限
    {
        FILE* fp = std::fopen("data.txt", "r");
        char buf[1u << 16];
        long long bytes = 0;
        size_t r = 0;
        auto t0 = Clock::now();
        while ((r = std::fread(buf, 1, sizeof(buf), fp)) > 0)
            bytes += static_cast<long long>(r);
        auto t1 = Clock::now();
        std::printf("fread raw        ms=%.1f bytes=%lld\n", to_ms(t1 - t0), bytes);
        std::fclose(fp);
    }
    // D：scanf 基线，与主基准同参数
    {
        FILE* fp = std::fopen("data.txt", "r");
        long long sum = 0;
        int x = 0;
        auto t0 = Clock::now();
        while (std::fscanf(fp, "%d", &x) == 1) sum += x;
        auto t1 = Clock::now();
        std::printf("fscanf %%d        ms=%.1f sum=%lld\n", to_ms(t1 - t0), sum);
        std::fclose(fp);
    }
    return 0;
}
