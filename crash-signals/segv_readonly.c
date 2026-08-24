/*
 * segv_readonly.c —— 写字符串字面量(只读段)
 *
 * 预期信号: SIGSEGV (11)  →  退出码 139
 *
 * 为什么崩:
 *   字符串字面量 "hello" 被编译器放进只读的 .rodata 段,对应页表项标记为
 *   只读(不可写)。地址是"合法且已映射"的,但写它触发的是**权限保护异常**
 *   ——不是"地址不存在",而是"这个地址你只能读不能写"。内核转成 SIGSEGV。
 *
 *   这正是 C++ 里 `char *s = "..."` 被废弃、应写 `const char *s` 的根本原因:
 *   类型系统本该在编译期就拦下这次写,而不是等到运行期崩溃。
 *
 * dmesg 特征: "segfault at <.rodata 地址>" 且 error 位标记为写操作。
 */
int main(void) {
    char *s = "hello";   /* s 指向 .rodata 里的只读字面量 */
    s[0] = 'H';          /* 写只读段 → 权限异常 → SIGSEGV */
    return 0;
}
