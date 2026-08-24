/*
 * fpe_divzero.c —— 整数除以 0
 *
 * 预期信号: SIGFPE (8)  →  退出码 136
 *
 * 为什么崩:
 *   CPU 执行整数除法指令(x86 的 idiv/div)时,若除数为 0(或结果溢出,如
 *   INT_MIN / -1),硬件抛出 #DE(Divide Error)异常,内核把它转成 SIGFPE。
 *   这是**同步信号**: 崩溃点就是那条除法指令。
 *
 * 反直觉点(重要):
 *   名字里的 FP 是"浮点",但**浮点除零默认不触发 SIGFPE**! 1.0/0.0 按 IEEE 754
 *   规则返回 inf,0.0/0.0 返回 nan,程序照跑不误。只有**整数**除/模零、INT_MIN/-1
 *   才是硬件异常。想让浮点异常也报 SIGFPE 需手动 feenableexcept()。
 *
 * 防优化: 除数来自 argc(运行期才知道值),否则编译器会在编译期算出 10/0 并直接
 *         报错或把它变成常量陷阱。
 */
#include <stdio.h>

int main(int argc, char **argv) {
    (void)argv;
    int a = 10;
    int b = argc - argc;       /* = 0,但编译器无法在编译期断定,避免被常量折叠 */
    int c = a / b;             /* 整数除零 → 硬件 #DE → SIGFPE */
    printf("%d\n", c);         /* 到不了这里 */
    return 0;
}
