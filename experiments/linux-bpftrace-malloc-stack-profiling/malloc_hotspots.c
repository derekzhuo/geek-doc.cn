/*
 * LP18 bpftrace malloc 调用栈剖析的示例目标程序。
 */
#define _POSIX_C_SOURCE 199309L
/*
 * 三个形态不同的分配点：高频小块、低频大块、中频会话对象。
 * 故意保留分配不释放，让内存增长可被外部观测，与线上「只涨不跌」症状同构。
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define ROUNDS 24
#define A_PER_ROUND 1500   /* 64 B 高频小块 */
#define B_PER_ROUND 400    /* 4 KiB 低频大块 */
#define C_PER_ROUND 750    /* 256 B 中频会话对象 */

static __attribute__((noinline)) void hot_path_a(void)
{
    char *p = malloc(64);
    if (!p) { perror("malloc a"); exit(1); }
    memset(p, 1, 64);
    /* 模拟处理后泄漏：不 free，地址随栈帧丢失 */
}

static __attribute__((noinline)) void loader_b(void)
{
    char *p = malloc(4096);
    if (!p) { perror("malloc b"); exit(1); }
    memset(p, 2, 4096);
}

static __attribute__((noinline)) void session_c(void)
{
    char *p = malloc(256);
    if (!p) { perror("malloc c"); exit(1); }
    memset(p, 3, 256);
}

int main(void)
{
    struct timespec ts = {0, 600 * 1000 * 1000}; /* 600 ms */
    printf("pid=%d start, rounds=%d\n", getpid(), ROUNDS);
    for (int r = 0; r < ROUNDS; ++r) {
        for (int i = 0; i < A_PER_ROUND; ++i)
            hot_path_a();
        for (int i = 0; i < B_PER_ROUND; ++i)
            loader_b();
        for (int i = 0; i < C_PER_ROUND; ++i)
            session_c();
        nanosleep(&ts, NULL);
    }
    printf("done\n");
    return 0;
}
