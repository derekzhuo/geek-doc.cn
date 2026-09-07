/*
 * abrt_heap_overflow.c —— 堆缓冲区溢出写坏元数据 → 下次 free 时 SIGABRT
 *
 * 预期信号: SIGABRT (6)  →  退出码 134  (Linux/glibc 上最标准)
 *
 * 为什么崩(核心机制):
 *   malloc 返回给你的是 chunk 里"用户可用"的那段,但紧邻它前后还有 glibc 的
 *   **管理元数据**(prev_size / size / 标志位),以及后一个 chunk 的头部。
 *
 *   往缓冲区**越界写**(下面写了远超申请大小的字节),会踩坏相邻 chunk 的 size
 *   字段等元数据。此刻**当场不崩**——数据只是被改花了。直到后续 free/malloc 时,
 *   glibc 校验 chunk 头(如发现 size 不合理、与相邻 chunk 对不上)才发现结构损坏,
 *   报 "malloc(): corrupted top size" / "free(): invalid next size" → abort()。
 *
 *   排查要点(与 double free 同源): **崩溃点(free/malloc 处)≠ 肇事点(越界写处)**。
 *   看到堆损坏类 abort,要去找"谁写越界了",而不是死盯 abort 那一行。
 *
 * 现象差异:
 *   - Linux/glibc: 稳定在下一次 free/malloc 时 SIGABRT。
 *   - macOS libmalloc: 检测点和文案不同,可能在 free 时报错,也可能表现不同。
 *
 * 注意: 这是 UB,-O0 下现象最稳定。
 */
#include <stdlib.h>
#include <string.h>

int main(void) {
    char *a = malloc(16);
    char *b = malloc(16);        /* b 紧跟在 a 后面,其 chunk 头就在 a 缓冲区之后 */
    (void)b;

    /* 越界写: 申请 16 字节却写 64 字节,踩坏 a 之后那个 chunk 的元数据头 */
    memset(a, 'A', 64);

    free(a);                     /* glibc 校验 chunk 头,可能在此发现损坏 */
    free(b);                     /* 或在这里: 检测到相邻 chunk 头被踩坏 → abort → SIGABRT */
    return 0;
}
