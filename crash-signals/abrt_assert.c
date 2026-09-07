/*
 * abrt_assert.c —— assert 断言失败
 *
 * 预期信号: SIGABRT (6)  →  退出码 134
 *
 * 为什么崩:
 *   assert(x) 在 x 为假时,先向 stderr 打印 "Assertion 'x' failed" + 文件行号,
 *   然后调用 abort() 主动终止进程。abort() 给自己发 SIGABRT,默认动作是 Core
 *   ——这是"程序自查后自首"的典型: 内部不变量被破坏,主动喊停留现场。
 *
 * 提示: assert 只在未定义 NDEBUG 时生效。Release 构建(-DNDEBUG)里 assert 会被
 *       整个消掉,断言表达式**不会执行**——所以别把有副作用的代码写进 assert。
 *       本 demo 的 Makefile 不加 -DNDEBUG,断言保持生效。
 */
#include <assert.h>

int main(void) {
    int x = 0;
    assert(x > 0 && "x 必须为正 (演示断言失败)");   /* 条件为假 → abort → SIGABRT */
    return 0;
}
