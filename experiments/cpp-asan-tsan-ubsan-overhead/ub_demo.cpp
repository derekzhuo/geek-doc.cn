// UBSan 检测能力演示：运行期输入触发有符号溢出与非法移位，各报一次后继续执行。
#include <climits>
#include <iostream>

__attribute__((noinline)) int overflow_add(int a, int b) { return a + b; }

__attribute__((noinline)) int bad_shift(int v, int sh) { return v << sh; }

int main(int argc, char** argv) {
    int seed = argc > 1 ? 1 : 0;  // 保证值来自运行期，避免被编译期常量折叠
    int a = INT_MAX - seed;
    int b = seed + 1;
    int y = overflow_add(a, b);
    int sh = 32 + seed;
    int z = bad_shift(1, sh);
    volatile int sink = y + z;
    std::cout << "ub_demo sink=" << sink << '\n';
    return 0;
}
