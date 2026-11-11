// 四种整数输入解析路径的同数据集吞吐基准：
//   scanf        : fscanf(fp, "%d", &x)
//   cin-default  : std::cin >> x，保持 sync_with_stdio(true) 默认状态
//   cin-fast     : sync_with_stdio(false) + tie(nullptr) 后 std::cin >> x
//   custom       : fread 64KB 整块缓冲 + 手写带符号整数解析
// 所有组读同一份 data.txt（200 万行，每行一个 int，含负数）。
// 每次进程调用完成一轮完整解析并输出耗时与校验和，7 轮中位由 run.sh
// 跨进程聚合，避免单进程内重复 freopen 带来的流状态污染。
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>

static constexpr int N = 2'000'000;
static constexpr const char* DATA_PATH = "data.txt";

static long long file_bytes() {
    std::ifstream f(DATA_PATH, std::ios::binary | std::ios::ate);
    return static_cast<long long>(f.tellg());
}

// 确定性 LCG 生成 200 万行整数，正负各半，值域约 +/- 5e7。
static void generate() {
    FILE* f = std::fopen(DATA_PATH, "w");
    if (!f) { std::perror("fopen"); std::exit(1); }
    unsigned int seed = 20261112u;
    for (int i = 0; i < N; ++i) {
        seed = seed * 1103515245u + 12345u;
        int v = static_cast<int>((seed >> 8) % 100'000'000u) - 50'000'000;
        std::fprintf(f, "%d\n", v);
    }
    std::fclose(f);
}

using Clock = std::chrono::steady_clock;

static double to_ms(Clock::duration d) {
    return std::chrono::duration<double, std::milli>(d).count();
}

static long long run_scanf() {
    long long sum = 0;
    FILE* fp = std::fopen(DATA_PATH, "r");
    int x = 0;
    while (std::fscanf(fp, "%d", &x) == 1) sum += x;
    std::fclose(fp);
    return sum;
}

static long long run_cin_default() {
    std::ios::sync_with_stdio(true);
    std::cin.tie(&std::cout);
    long long sum = 0;
    int x = 0;
    while (std::cin >> x) sum += x;
    return sum;
}

static long long run_cin_fast() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    long long sum = 0;
    int x = 0;
    while (std::cin >> x) sum += x;
    return sum;
}

// 自定义快读：fread 整块进用户缓冲，手写逐字符整数解析。
namespace fastread {
static constexpr size_t BUFSZ = 1u << 16;
static char buf[BUFSZ];
static size_t buf_len = 0;
static size_t buf_pos = 0;

static inline int getc_fast() {
    if (buf_pos == buf_len) {
        buf_len = std::fread(buf, 1, BUFSZ, stdin);
        buf_pos = 0;
        if (buf_len == 0) return -1;
    }
    return static_cast<unsigned char>(buf[buf_pos++]);
}

static inline bool read_int(int& out) {
    int c = getc_fast();
    while (c != -1 && c != '-' && (c < '0' || c > '9')) c = getc_fast();
    if (c == -1) return false;
    int sign = 1;
    if (c == '-') { sign = -1; c = getc_fast(); }
    int x = 0;
    while (c >= '0' && c <= '9') {
        x = x * 10 + (c - '0');
        c = getc_fast();
    }
    out = x * sign;
    return true;
}
}  // namespace fastread

static long long run_custom() {
    long long sum = 0;
    int x = 0;
    while (fastread::read_int(x)) sum += x;
    return sum;
}

static void bench(const char* group, long long (*fn)(), bool use_stdin) {
    const long long bytes = file_bytes();
    if (use_stdin) {
        if (!std::freopen(DATA_PATH, "r", stdin)) {
            std::perror("freopen"); std::exit(1);
        }
    }
    auto t0 = Clock::now();
    long long checksum = fn();
    auto t1 = Clock::now();
    double ms = to_ms(t1 - t0);
    double mlines = (N / 1'000'000.0) / (ms / 1000.0);
    double mbps = (bytes / 1'000'000.0) / (ms / 1000.0);
    std::printf("group=%s N=%d bytes=%lld ms=%.3f throughput=%.3f Mlines/s "
                "%.3f MB/s checksum=%lld\n",
                group, N, bytes, ms, mlines, mbps, checksum);
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::fprintf(stderr, "usage: %s gen|scanf|cin-default|cin-fast|custom\n",
                     argv[0]);
        return 2;
    }
    std::string mode = argv[1];
    if (mode == "gen") {
        generate();
        std::printf("generated %d ints -> %s (%lld bytes)\n", N, DATA_PATH,
                    file_bytes());
        return 0;
    }
    if (mode == "scanf") bench("scanf", run_scanf, false);
    else if (mode == "cin-default") bench("cin-default", run_cin_default, true);
    else if (mode == "cin-fast") bench("cin-fast", run_cin_fast, true);
    else if (mode == "custom") bench("custom", run_custom, true);
    else { std::fprintf(stderr, "unknown mode: %s\n", mode.c_str()); return 2; }
    return 0;
}
