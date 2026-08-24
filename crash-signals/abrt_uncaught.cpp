/*
 * abrt_uncaught.cpp —— C++ 未捕获异常
 *
 * 预期信号: SIGABRT (6)  →  退出码 134
 *
 * 为什么崩:
 *   throw 抛出异常后,C++ 运行时(libstdc++/libc++)沿调用栈向上找匹配的 catch。
 *   若一路找到 main 之外都没人接,运行时调用 std::terminate(),它默认再调
 *   abort() → SIGABRT。
 *
 *   典型现场输出: "terminate called after throwing an instance of 'std::runtime_error'"
 *                 "  what():  boom"
 *   这是识别"未捕获异常"最直接的线索——一看到 terminate called 就往异常上查。
 *
 * 同类: std::vector::at() 越界抛 std::out_of_range 无人 catch,也走这条路径。
 */
#include <stdexcept>

int main() {
    throw std::runtime_error("boom: 未捕获异常演示");   /* 无 catch → terminate → abort */
    return 0;
}
