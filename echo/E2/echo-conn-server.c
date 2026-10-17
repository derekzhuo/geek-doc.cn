// echo-conn-server.c — E2 百万长连接专用 hold 服务器
// 与 day-04/echo-mt-server.c 的区别：不保留每连接 4KB 缓冲，收到数据读后即弃，
// 进程内存占用与连接数近似无关（内核 socket/slab 开销照实），用于测量
// 「单机维持 1M 长连接」的内核侧成本，而非应用层吞吐。
//
// 用法: echo-conn-server <port> <threads>
// 输出(每 5 秒一行): ts estab=<当前连接数> accepted=<累计> rss_kb=<进程RSS>
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>

#define MAX_EVENTS 1024

static volatile sig_atomic_t running = 1;
static void on_sig(int s) { (void)s; running = 0; }

static _Atomic long g_estab = 0;     // 当前存活连接（全线程合计）
static _Atomic long g_accepted = 0;  // 累计 accept 数

static long now_ms(void) {
    struct timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000L + ts.tv_nsec / 1000000L;
}

static long proc_rss_kb(void) {
    FILE *f = fopen("/proc/self/status", "r");
    if (!f) return -1;
    char line[256]; long kb = -1;
    while (fgets(line, sizeof line, f))
        if (sscanf(line, "VmRSS: %ld kB", &kb) == 1) break;
    fclose(f);
    return kb;
}

static int set_nonblocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

struct worker_arg { int port; };

static void *worker(void *p) {
    struct worker_arg *wa = p;
    int lfd = socket(AF_INET, SOCK_STREAM, 0);
    if (lfd < 0) { perror("socket"); return NULL; }
    int one = 1;
    setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
    setsockopt(lfd, SOL_SOCKET, SO_REUSEPORT, &one, sizeof one);
    set_nonblocking(lfd);
    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(wa->port);
    if (bind(lfd, (struct sockaddr *)&addr, sizeof addr) < 0) { perror("bind"); return NULL; }
    if (listen(lfd, 65535) < 0) { perror("listen"); return NULL; }

    int ep = epoll_create1(0);
    struct epoll_event ev = { .events = EPOLLIN, .data.fd = lfd };
    epoll_ctl(ep, EPOLL_CTL_ADD, lfd, &ev);

    struct epoll_event evs[MAX_EVENTS];
    char scratch[4096];  // 每线程一块读弃缓冲，不按连接分配
    while (running) {
        int n = epoll_wait(ep, evs, MAX_EVENTS, 1000);
        for (int i = 0; i < n; i++) {
            int fd = evs[i].data.fd;
            if (fd == lfd) {
                for (;;) {
                    int cfd = accept(lfd, NULL, NULL);
                    if (cfd < 0) break;  // EAGAIN
                    set_nonblocking(cfd);
                    setsockopt(cfd, SOL_SOCKET, SO_KEEPALIVE, &one, sizeof one);  // T11 死连接回收依赖
                    struct epoll_event cev = { .events = EPOLLIN | EPOLLRDHUP | EPOLLERR, .data.fd = cfd };
                    if (epoll_ctl(ep, EPOLL_CTL_ADD, cfd, &cev) < 0) { close(cfd); continue; }
                    __atomic_add_fetch(&g_estab, 1, __ATOMIC_RELAXED);
                    __atomic_add_fetch(&g_accepted, 1, __ATOMIC_RELAXED);
                }
            } else {
                if (evs[i].events & EPOLLIN) {
                    ssize_t r = read(fd, scratch, sizeof scratch);
                    if (r > 0 && !(evs[i].events & (EPOLLRDHUP | EPOLLERR))) continue;
                }
                epoll_ctl(ep, EPOLL_CTL_DEL, fd, NULL);
                close(fd);
                __atomic_sub_fetch(&g_estab, 1, __ATOMIC_RELAXED);
            }
        }
    }
    close(lfd);
    close(ep);
    return NULL;
}

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: %s <port> <threads>\n", argv[0]); return 2; }
    int port = atoi(argv[1]), threads = atoi(argv[2]);

    struct rlimit rl = { RLIM_INFINITY, RLIM_INFINITY };
    setrlimit(RLIMIT_NOFILE, &rl);

    signal(SIGINT, on_sig); signal(SIGTERM, on_sig);
    signal(SIGPIPE, SIG_IGN);

    pthread_t tids[128];
    struct worker_arg wa = { .port = port };
    if (threads > 128) threads = 128;
    for (int i = 0; i < threads; i++)
        if (pthread_create(&tids[i], NULL, worker, &wa) != 0) { perror("pthread_create"); return 1; }

    long last = now_ms();
    while (running) {
        usleep(200 * 1000);
        long now = now_ms();
        if (now - last >= 5000) {
            last = now;
            printf("%ld estab=%ld accepted=%ld rss_kb=%ld\n",
                   (long)time(NULL),
                   __atomic_load_n(&g_estab, __ATOMIC_RELAXED),
                   __atomic_load_n(&g_accepted, __ATOMIC_RELAXED),
                   proc_rss_kb());
            fflush(stdout);
        }
    }
    printf("%ld EXIT estab=%ld accepted=%ld\n", (long)time(NULL),
           __atomic_load_n(&g_estab, __ATOMIC_RELAXED),
           __atomic_load_n(&g_accepted, __ATOMIC_RELAXED));
    return 0;
}
