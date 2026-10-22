#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <signal.h>

/* 业务线程 —— 主逻辑 */
static void *worker(void *arg)
{
    int n = *(int *)arg;
    printf("worker %d: doing work...\n", n);
    /* 模拟长期运行: sleep(100); */
    return NULL;
}

/* 信号专用线程 */
static void *signal_thread(void *arg)
{
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGTERM);
    sigaddset(&set, SIGINT);
    int sig;
    while (1) {
        if (sigwait(&set, &sig) != 0) { perror("sigwait"); continue; }
        printf("[signal thread] got %s\n",
               sig == SIGTERM ? "SIGTERM" : "SIGINT");
        if (sig == SIGTERM || sig == SIGINT) {
            /* ★ 这里可以安全调用任何函数: */
            printf("[signal thread] initiating graceful shutdown...\n");
            /* 通知 worker 线程退出, 收尾, ... */
            exit(0);   /* 演示用: 直接退出 */
        }
    }
    return NULL;
}

int main(void)
{
    /* 关键: 在创建任何线程之前屏蔽目标信号! */
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGTERM);
    sigaddset(&set, SIGINT);
    pthread_sigmask(SIG_BLOCK, &set, NULL);   /* 本线程屏蔽, 子线程继承 */

    /* 启动信号线程 —— 它继承屏蔽字, 成为 sigwait 的唯一消费者 */
    pthread_t stid;
    pthread_create(&stid, NULL, signal_thread, NULL);

    /* 启动业务线程 */
    pthread_t wtid;
    int arg = 42;
    pthread_create(&wtid, NULL, worker, &arg);

    printf("main: pid=%d, send 'kill -TERM %d' to trigger\n", getpid(), getpid());
    pthread_join(stid, NULL);   /* 信号线程不退出, 这里一直等 */
    return 0;
}

