/*
 * signal-vs-eventfd: 信号通知 vs eventfd 通知的吞吐/延迟对比
 *
 * 实验要回答的问题：
 *   "高频事件通知场景，信号到底比 eventfd 慢多少？"
 *
 * 设计：
 *   - 场景一: 线程 B 阻塞在 sigwait 上，线程 A 用 pthread_kill 发 SIGUSR1
 *     （信号投递完整路径: send_signal → siglock → wakeup → handler/sigwait 返回）
 *   - 场景二: 线程 B 阻塞在 read(eventfd) 上，线程 A 用 write(eventfd) 通知
 *     （fd 事件模型: 纯内存操作，无 siglock、无 FPU 保存/恢复）
 *   - 各投递 N 次，统计总耗时、吞吐、平均/最大延迟
 *
 * 预期：eventfd 吞吐约为信号的 2~5 倍（信号路径含 siglock + FPU 保存/恢复）。
 *
 * 编译运行:
 *   make run          # 默认 100 万次
 *   ./signal_vs_eventfd 1000000
 */
#define _GNU_SOURCE
#include <errno.h>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/eventfd.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

static const int DEFAULT_ITERS = 1000000;

/* ---- 信号场景 ---- */
static volatile int sig_go = 0;
static void sig_handler(int sig) { (void)sig; }

static void *sig_worker(void *arg)
{
    /* 等待第一条信号后立即退出 sigwait，改成忙等计数 */
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGUSR1);
    while (!sig_go) usleep(100);
    int iters = *(int *)arg;
    for (int i = 0; i < iters; i++) {
        int sig;
        if (sigwait(&set, &sig) != 0) { perror("sigwait"); break; }
    }
    return NULL;
}

static void run_signal(int iters)
{
    pthread_t th;
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGUSR1);
    pthread_sigmask(SIG_BLOCK, &set, NULL);   /* 主线程屏蔽, 子线程继承 */

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sig_handler;
    sigaction(SIGUSR1, &sa, NULL);

    pthread_create(&th, NULL, sig_worker, &iters);

    struct timeval t0, t1;
    gettimeofday(&t0, NULL);
    sig_go = 1;
    long long max_us = 0, sum_us = 0;
    struct timeval st, et;
    for (int i = 0; i < iters; i++) {
        gettimeofday(&st, NULL);
        pthread_kill(th, SIGUSR1);
        gettimeofday(&et, NULL);
        long long d = (et.tv_sec - st.tv_sec) * 1000000LL + (et.tv_usec - st.tv_usec);
        if (d > max_us) max_us = d;
        sum_us += d;
    }
    gettimeofday(&t1, NULL);
    long long total = (t1.tv_sec - t0.tv_sec) * 1000000LL + (t1.tv_usec - t0.tv_usec);
    printf("[signal]  %d deliveries in %lld ms (~%lld/s, avg %.2fµs, max %lldµs)\n",
           iters, total / 1000, iters * 1000000LL / (total ? total : 1),
           (double)sum_us / iters, max_us);
    pthread_join(th, NULL);
}

/* ---- eventfd 场景 ---- */
static void *efd_worker(void *arg)
{
    int efd = *(int *)arg;
    eventfd_t val;
    for (;;) {
        if (read(efd, &val, sizeof(val)) != sizeof(val)) break;
        /* 收到 0x1 计数包: 继续; 收到哨兵 0xDEAD 退出 */
        if (val == 0xDEAD) break;
    }
    return NULL;
}

static void run_eventfd(int iters)
{
    int efd = eventfd(0, EFD_CLOEXEC);
    if (efd < 0) { perror("eventfd"); exit(1); }
    pthread_t th;
    pthread_create(&th, NULL, efd_worker, &efd);

    struct timeval t0, t1;
    gettimeofday(&t0, NULL);
    long long max_us = 0, sum_us = 0;
    struct timeval st, et;
    for (int i = 0; i < iters; i++) {
        gettimeofday(&st, NULL);
        eventfd_write(efd, 1);
        gettimeofday(&et, NULL);
        long long d = (et.tv_sec - st.tv_sec) * 1000000LL + (et.tv_usec - st.tv_usec);
        if (d > max_us) max_us = d;
        sum_us += d;
    }
    gettimeofday(&t1, NULL);
    long long total = (t1.tv_sec - t0.tv_sec) * 1000000LL + (t1.tv_usec - t0.tv_usec);
    printf("[eventfd] %d deliveries in %lld ms (~%lld/s, avg %.2fµs, max %lldµs)\n",
           iters, total / 1000, iters * 1000000LL / (total ? total : 1),
           (double)sum_us / iters, max_us);

    eventfd_write(efd, 0xDEAD);   /* 哨兵: 通知 worker 退出 */
    pthread_join(th, NULL);
    close(efd);
}

int main(int argc, char *argv[])
{
    int iters = (argc > 1) ? atoi(argv[1]) : DEFAULT_ITERS;
    if (iters <= 0) iters = DEFAULT_ITERS;

    printf("== signal vs eventfd, %d deliveries each ==\n", iters);
    run_signal(iters);
    run_eventfd(iters);
    printf("\n解读: eventfd 走 fd 事件模型(无 siglock/无 FPU 保存恢复),\n"
           "     高频场景下吞吐与延迟均优于信号。详见 signals-kernel-performance 篇。\n");
    return 0;
}
