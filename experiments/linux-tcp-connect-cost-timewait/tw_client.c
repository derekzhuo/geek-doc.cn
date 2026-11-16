/*
 * 短连接对照实验客户端：每个连接发一次请求、读完响应立刻 close，
 * 主动关闭方在客户端，TIME_WAIT 占用本机临时端口。
 * 按 errno 分类统计 connect 失败数（EADDRNOTAVAIL=99 即临时端口耗尽）。
 */
#define _POSIX_C_SOURCE 200809L
#include <netinet/in.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>

struct stats {
    long success;
    long fail_addr;   /* EADDRNOTAVAIL：临时端口耗尽 */
    long fail_other;
};

struct worker_arg {
    const char *host;
    int port;
    long count;
    struct stats st;
};

static void *worker(void *p)
{
    struct worker_arg *a = p;
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((unsigned short)a->port);
    inet_pton(AF_INET, a->host, &addr.sin_addr);

    for (long i = 0; i < a->count; ++i) {
        int fd = socket(AF_INET, SOCK_STREAM, 0);
        if (fd < 0) { a->st.fail_other++; continue; }
        if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
            if (errno == EADDRNOTAVAIL) a->st.fail_addr++;
            else { a->st.fail_other++; }
            close(fd);
            continue;
        }
        (void)send(fd, "GET / HTTP/1.0\r\n\r\n", 18, 0);
        char buf[256];
        (void)recv(fd, buf, sizeof(buf), 0);
        close(fd);   /* 客户端主动关闭 → 客户端 TIME_WAIT */
        a->st.success++;
    }
    return NULL;
}

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

int main(int argc, char **argv)
{
    if (argc != 5) {
        fprintf(stderr, "用法: %s <host> <port> <总连接数> <并发线程数>\n", argv[0]);
        return 1;
    }
    const char *host = argv[1];
    int port = atoi(argv[2]);
    long total = atol(argv[3]);
    int threads = atoi(argv[4]);
    if (threads <= 0 || total <= 0) return 1;

    pthread_t *tids = calloc((size_t)threads, sizeof(pthread_t));
    struct worker_arg *args = calloc((size_t)threads, sizeof(*args));
    double t0 = now_s();
    for (int i = 0; i < threads; ++i) {
        args[i].host = host;
        args[i].port = port;
        args[i].count = total / threads + (i < total % threads ? 1 : 0);
        pthread_create(&tids[i], NULL, worker, &args[i]);
    }
    struct stats all = {0};
    for (int i = 0; i < threads; ++i) {
        pthread_join(tids[i], NULL);
        all.success += args[i].st.success;
        all.fail_addr += args[i].st.fail_addr;
        all.fail_other += args[i].st.fail_other;
    }
    double elapsed = now_s() - t0;
    long attempted = all.success + all.fail_addr + all.fail_other;
    printf("attempted=%ld success=%ld fail_eaddrnotavail=%ld fail_other=%ld\n",
           attempted, all.success, all.fail_addr, all.fail_other);
    printf("elapsed=%.3fs rps=%.1f\n",
           elapsed, attempted > 0 ? all.success / elapsed : 0.0);
    free(tids); free(args);
    return 0;
}
