/*
 * segv_stackoverflow.c —— 无限递归导致栈溢出
 *
 * 预期信号: SIGSEGV (11)  →  退出码 139
 *
 * 为什么崩:
 *   每次函数调用都在栈上压入一个新栈帧(返回地址+局部变量)。无限递归让栈
 *   不断向低地址生长,最终撞到栈区末尾的 **guard page(保护页)**——这是内核
 *   在栈下方放的一页不可访问内存,专门用来"接住"栈溢出。一旦写到 guard page,
 *   触发保护异常 → SIGSEGV。
 *
 *   注意与"堆越界"的区别: 栈溢出的出错地址紧邻栈顶、在栈范围之外的低地址。
 *
 * 防优化: recurse() 带一个随每层变化的参数并累加,避免编译器把无限递归识别成
 *         死循环或做尾调用优化(tail-call)把递归压成迭代而不再增长栈。
 */
volatile int sink;

static int recurse(int depth) {
    volatile int buf[64];      /* 每帧占一块栈空间,加速栈耗尽 */
    buf[0] = depth;
    buf[63] = depth;
    sink = buf[0] + buf[63];
    return recurse(depth + 1) + buf[0];   /* 非尾调用: 返回后还要用 buf[0] */
}

int main(void) {
    return recurse(0);         /* 递归到栈耗尽 → 撞 guard page → SIGSEGV */
}
