/*
 * ill_badfnptr.c —— 跳到坏函数指针
 *
 * 预期信号: SIGILL (4) 或 SIGSEGV (11)  →  退出码 132 或 139
 *
 * 为什么崩:
 *   把一个乱写的地址当函数指针来 call,控制流"跑飞"到一片非代码区。落点性质
 *   决定报哪个信号:
 *     - 落到**没映射 / 无执行权限**的地址 → 取指失败 → SIGSEGV;
 *     - 落到**能读能执行、但内容不是合法指令**的地方 → CPU 译码失败 → SIGILL。
 *   所以 SIGILL 与 SIGSEGV 常同源(都是控制流跑飞),区别只在落点。
 *
 *   现代系统开启 NX(不可执行)+ W^X 后,普通数据区不可执行,坏函数指针更常见的
 *   结局是 SIGSEGV;某些地址/平台上会得到 SIGILL。两者都算"跳飞"的正常表现。
 *
 * 现象差异: macOS(arm64)与 Linux(x86-64)因内存布局/保护策略不同,具体是
 *           SIGILL 还是 SIGSEGV/SIGBUS 可能不一样——README 有说明。
 */
int main(void) {
    void (*fp)(void) = (void (*)(void))0xdeadbeef;   /* 乱指的函数指针 */
    fp();                                            /* call 到非代码区 → SIGILL / SIGSEGV */
    return 0;
}
