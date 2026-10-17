// conn-ramper.c — E2 百万长连接爬升客户端
// epoll 管理 N 条 TCP 长连接：按目标速率建连、保持、统计建连速率/失败数。
// 用法: conn-ramper <server-ip> <port> <target> <rate-per-sec> <src-ip-file> [--hold-sec N]
//   src-ip-file: 每行一个本机源 IP（多 IP 突破单 IP 6 万端口上限）
// 输出(每 5 秒一行): ts established rate_5s fail mem_kb
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/resource.h>
#include <time.h>
#include <unistd.h>

#define MAXSRC 64
#define BATCH 512

static volatile int stop = 0;
static void on_sig(int s) { (void)s; stop = 1; }

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

int main(int argc, char **argv) {
    if (argc < 6) {
        fprintf(stderr, "usage: %s <server-ip> <port> <target> <rate-per-sec> <src-ip-file> [--hold-sec N]\n", argv[0]);
        return 2;
    }
    const char *sip = argv[1];
    int port = atoi(argv[2]);
    long target = atol(argv[3]);
    long rate = atol(argv[4]);
    const char *srcfile = argv[5];
    long hold_sec = 0;
    if (argc >= 8 && strcmp(argv[6], "--hold-sec") == 0) hold_sec = atol(argv[7]);

    struct rlimit rl = { RLIM_INFINITY, RLIM_INFINITY };
    setrlimit(RLIMIT_NOFILE, &rl);

    struct in_addr srcs[MAXSRC]; int nsrc = 0;
    FILE *sf = fopen(srcfile, "r");
    if (!sf) { perror("src-ip-file"); return 2; }
    char buf[64];
    while (nsrc < MAXSRC && fgets(buf, sizeof buf, sf)) {
        if (inet_pton(AF_INET, strtok(buf, " \n"), &srcs[nsrc]) == 1) nsrc++;
    }
    fclose(sf);
    if (nsrc == 0) { fprintf(stderr, "no src ip\n"); return 2; }

    int ep = epoll_create1(0);
    if (ep < 0) { perror("epoll_create1"); return 1; }

    struct sockaddr_in dst = {0};
    dst.sin_family = AF_INET;
    dst.sin_port = htons(port);
    inet_pton(AF_INET, sip, &dst.sin_addr);

    signal(SIGINT, on_sig); signal(SIGTERM, on_sig);

    long established = 0, fail = 0, opened = 0, dropped = 0, eaddr = 0, einuse = 0;
    long t0 = now_ms(), last_report = t0, last_est = 0;
    int src_idx = 0;
    long port_cursor[MAXSRC] = {0};
    struct epoll_event evs[BATCH];

    // 每 fd 状态：0=连接中 1=已计数。established 只在 0→1 翻转时 +1，RDHUP 关闭时 -1，
    // 防止对同一 fd 重复计数（此前 est 超过真实 socket 数的 bug 根因）。
    long maxfd = 1 << 21;
    unsigned char *fdstate = calloc(maxfd, 1);
    if (!fdstate) { perror("calloc fdstate"); return 1; }

    while (!stop) {
        // 按速率预算开新连接（非阻塞 connect，先入 epoll 等可写）
        long elapsed_ms = now_ms() - t0;
        long budget = rate * elapsed_ms / 1000 - opened;
        if (opened >= target) budget = 0;
        for (long i = 0; i < budget && i < BATCH * 4; i++) {
            int fd = socket(AF_INET, SOCK_STREAM, 0);
            if (fd < 0) { fail++; break; }
            // 应用侧显式分配端口：内核 bind(0) 临时端口搜索在 ~30 万条绑定后
            // 退化为每次数十 ms（bhash 链扫描），这里绕开内核分配器。
            struct sockaddr_in la = {0};
            la.sin_family = AF_INET;
            la.sin_addr = srcs[src_idx];
            la.sin_port = htons(10000 + (unsigned short)(port_cursor[src_idx]++ % 55001));
            src_idx = (src_idx + 1) % nsrc;
            if (bind(fd, (struct sockaddr *)&la, sizeof la) < 0) {
                if (errno == EADDRINUSE) { einuse++; close(fd); continue; }
                fail++; close(fd); continue;
            }
            fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK);
            int rc = connect(fd, (struct sockaddr *)&dst, sizeof dst);
            if (rc < 0 && errno != EINPROGRESS) {
                fail++; eaddr += (errno == EADDRNOTAVAIL);
                close(fd); continue;
            }
            struct epoll_event ev = { .events = EPOLLOUT | EPOLLERR | EPOLLRDHUP, .data.fd = fd };
            if (epoll_ctl(ep, EPOLL_CTL_ADD, fd, &ev) < 0) { fail++; close(fd); continue; }
            opened++;
        }
        int n = epoll_wait(ep, evs, BATCH, 200);
        for (int i = 0; i < n; i++) {
            int fd = evs[i].data.fd;
            int err = 0; socklen_t l = sizeof err;
            getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &l);
            if (err) { fail++; close(fd); continue; }
            if (fd < maxfd && fdstate[fd] == 0) {
                fdstate[fd] = 1;
                established++;
                struct epoll_event ev = { .events = EPOLLRDHUP | EPOLLERR, .data.fd = fd };
                epoll_ctl(ep, EPOLL_CTL_MOD, fd, &ev);
            } else {
                // 已计数连接的 RDHUP/ERR：服务端断开，关闭并下修计数
                if (fd < maxfd) fdstate[fd] = 0;
                epoll_ctl(ep, EPOLL_CTL_DEL, fd, NULL);
                close(fd);
                established--;
                dropped++;
            }
        }
        long now = now_ms();
        if (now - last_report >= 5000) {
            double r = (established - last_est) * 1000.0 / (now - last_report);
            printf("%ld est=%ld opened=%ld budget=%ld rate=%.0f/s fail=%ld eaddr=%ld einuse=%ld dropped=%ld rss_kb=%ld\n",
                   (long)time(NULL), established, opened, budget, r, fail, eaddr, einuse, dropped, proc_rss_kb());
            fflush(stdout);
            last_report = now; last_est = established;
        }
        if (established >= target) {
            if (hold_sec > 0) {
                long hold_until = now + hold_sec * 1000;
                while (!stop && now_ms() < hold_until) {
                    int m = epoll_wait(ep, evs, BATCH, 1000);
                    for (int i = 0; i < m; i++) {
                        int fd = evs[i].data.fd;
                        if (fd < maxfd) fdstate[fd] = 0;
                        epoll_ctl(ep, EPOLL_CTL_DEL, fd, NULL);
                        close(fd);
                        established--;
                        dropped++;
                    }
                    if (now_ms() - last_report >= 5000) {
                        last_report = now_ms();
                        printf("%ld HOLD est=%ld fail=%ld dropped=%ld rss_kb=%ld\n",
                               (long)time(NULL), established, fail, dropped, proc_rss_kb());
                        fflush(stdout);
                    }
                }
            }
            break;
        }
    }
    printf("%ld DONE est=%ld fail=%ld dropped=%ld rss_kb=%ld\n", (long)time(NULL), established, fail, dropped, proc_rss_kb());
    return 0;
}
