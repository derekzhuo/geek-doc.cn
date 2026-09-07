/*
 * abrt_double_free.c —— 重点: double free 为什么崩
 *
 * 预期信号: SIGABRT (6)  →  退出码 134  (在 Linux/glibc 上最标准)
 *
 * 为什么崩(核心机制):
 *   glibc 的 malloc 用 **chunk** 管理堆。free 掉一块 chunk 后,它不会立刻还给
 *   内核,而是被挂进一个空闲链表(tcache / fastbin / freelist)——链表的 next
 *   指针**就借用 chunk 自身内部的空间**来存。
 *
 *   double free 时,同一个 chunk 被**第二次挂进链表**,于是它在链表里出现两次,
 *   链表结构被破坏(可能成环、可能 next 指向自己)。glibc 为此加了完整性检查:
 *     - tcache: 每个 chunk 有一个 key 字段,free 时若发现 key 已等于 tcache 标记,
 *               判定为疑似 double free → 主动 abort();
 *     - fastbin: free 时检查"链表头是不是就是正在 free 的这块"→ 命中则报
 *               "double free or corruption (fasttop)" → abort()。
 *
 *   关键排查要点: **不是 free 本身立刻崩,而是 free 破坏了链表结构后,glibc 在
 *   检测到异常的那一刻主动 abort**。所以崩溃点(abort 的调用栈)常常**不是**真正
 *   肇事的那次 free/那行代码——要回溯指针的生命周期。
 *
 * 现象差异:
 *   - Linux/glibc: 稳定 SIGABRT,并打印 "free(): double free detected in tcache 2"。
 *   - macOS: 分配器是 libmalloc 而非 glibc,报 "pointer being freed was not
 *            allocated" 或类似,同样 abort → SIGABRT,但文案不同。
 */
#include <stdlib.h>
#include <string.h>

int main(void) {
    char *p = malloc(64);
    strcpy(p, "some data");
    free(p);          /* 第一次: 合法,chunk 被挂进 tcache */
    free(p);          /* 第二次: 同一 chunk 重复挂链 → glibc 检测 → abort → SIGABRT */
    return 0;
}
