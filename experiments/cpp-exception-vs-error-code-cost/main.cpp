#include <chrono>
#include <cstdio>
#include <stdexcept>
#include "logic.hpp"

// 两种场景 × 三种机制 = 6 个测量单元，每个 runner 独占 noinline 函数，
// 便于按符号截取反汇编核对正常路径上是否还有异常处理指令。
constexpr long OK_ITERS = 50'000'000L;     // 全合法输入，量正常路径
constexpr long FAIL_ITERS = 2'000'000L;    // 全非法输入，量错误路径（抛异常很慢，次数小一档）
constexpr int TOKEN_LEN = 4;

using Clock = std::chrono::steady_clock;

static double elapsed_ms(Clock::time_point t0, Clock::time_point t1) {
    return std::chrono::duration_cast<std::chrono::microseconds>(t1 - t0).count()
           / 1000.0;
}

// 确定性 LCG 生成 token，三机制拿到逐字节相同的输入序列。
struct TokenGen {
    unsigned long seed = 20261111;
    void next(char* tok, bool valid) {
        seed = (seed * 1103515245UL + 12345UL) & 0x7fffffffUL;
        if (valid) {
            for (int i = 0; i < TOKEN_LEN; ++i) {
                tok[i] = static_cast<char>('0' + ((seed >> i) & 7) + (i & 1));
                if (tok[i] > '9') tok[i] = '9';
            }
        } else {
            tok[0] = '#';  // 首字符即非法，第一时间命中错误分支
            for (int i = 1; i < TOKEN_LEN; ++i) tok[i] = '0';
        }
    }
};

__attribute__((noinline))
long run_except_ok(long n) {
    TokenGen gen;
    char tok[TOKEN_LEN + 1] = {0};
    long sum = 0;
    for (long i = 0; i < n; ++i) {
        gen.next(tok, true);
        sum += parseExcept(tok, TOKEN_LEN);
    }
    return sum;
}

__attribute__((noinline))
long run_except_fail(long n) {
    TokenGen gen;
    char tok[TOKEN_LEN + 1] = {0};
    long caught = 0;
    for (long i = 0; i < n; ++i) {
        gen.next(tok, false);
        try {
            (void)parseExcept(tok, TOKEN_LEN);
        } catch (const std::exception&) {
            ++caught;
        }
    }
    return caught;
}

__attribute__((noinline))
long run_code_ok(long n) {
    TokenGen gen;
    char tok[TOKEN_LEN + 1] = {0};
    long sum = 0;
    for (long i = 0; i < n; ++i) {
        gen.next(tok, true);
        int out = 0;
        if (parseCode(tok, TOKEN_LEN, out) == 0) sum += out;
    }
    return sum;
}

__attribute__((noinline))
long run_code_fail(long n) {
    TokenGen gen;
    char tok[TOKEN_LEN + 1] = {0};
    long errors = 0;
    for (long i = 0; i < n; ++i) {
        gen.next(tok, false);
        int out = 0;
        if (parseCode(tok, TOKEN_LEN, out) != 0) ++errors;
    }
    return errors;
}

__attribute__((noinline))
long run_expected_ok(long n) {
    TokenGen gen;
    char tok[TOKEN_LEN + 1] = {0};
    long sum = 0;
    for (long i = 0; i < n; ++i) {
        gen.next(tok, true);
        ExpectedInt e = parseExpected(tok, TOKEN_LEN);
        if (e.ok()) sum += e.value;
    }
    return sum;
}

__attribute__((noinline))
long run_expected_fail(long n) {
    TokenGen gen;
    char tok[TOKEN_LEN + 1] = {0};
    long errors = 0;
    for (long i = 0; i < n; ++i) {
        gen.next(tok, false);
        ExpectedInt e = parseExpected(tok, TOKEN_LEN);
        if (!e.ok()) ++errors;
    }
    return errors;
}

template <typename Fn>
void bench(const char* mechanism, const char* path, long iters, Fn fn) {
    fn(iters / 100);  // 预热
    const auto t0 = Clock::now();
    const long checksum = fn(iters);
    const auto t1 = Clock::now();
    std::printf("mechanism=%-9s path=%-5s iters=%ld elapsed_ms=%8.3f checksum=%ld\n",
                mechanism, path, iters, elapsed_ms(t0, t1), checksum);
}

int main() {
    bench("exception", "ok", OK_ITERS, run_except_ok);
    bench("exception", "fail", FAIL_ITERS, run_except_fail);
    bench("errcode", "ok", OK_ITERS, run_code_ok);
    bench("errcode", "fail", FAIL_ITERS, run_code_fail);
    bench("expected", "ok", OK_ITERS, run_expected_ok);
    bench("expected", "fail", FAIL_ITERS, run_expected_fail);
    return 0;
}
