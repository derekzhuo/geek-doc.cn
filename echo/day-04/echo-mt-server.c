/*
 * echo-mt-server.c — 多线程 epoll echo 服务端（thread-per-core + SO_REUSEPORT）
 *
 * 设计动机（来自 Day 3 结论 8.3）：
 *   单线程 epoll 服务端在 500 并发就触顶（QPS 平台期 2700-3900），
 *   长连接的吞吐优势需要"服务端有并发处理能力"才能充分兑现。
 *
 * 本程序实现业界标准的 thread-per-core 模型：
 *   1. 每个线程独立 socket() + SO_REUSEPORT + bind() + listen() + epoll_create1()
 *   2. SO_REUSEPORT 让内核把新连接按四元组哈希**均匀分发**到各线程的 listen 队列
 *   3. 每个线程独享自己的 epoll 与连接表，无共享锁
 *   4. 每线程绑定一个 CPU 核（sched_setaffinity），最大化 L1/L2 缓存亲和
 *
 * 用法：
 *   ./echo-mt-server [port] [threads] [mode]
 *     port    默认 9988
 *     threads 默认 4（建议 = 物理核数）
 *     mode    lt | et，默认 et（与 Day 2/3 服务端语义一致）
 *
 * 与 Day 2/3 单线程版对比：
 *   - 单线程：一个 epoll 管所有 fd，500 并发触顶
 *   - 本版：  每线程一个 epoll，连接被内核分流，理论上吞吐 ×N
 */

#define _GNU_SOURCE   /* CPU_ZERO/CPU_SET/sched_setaffinity/sched_getcpu */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <pthread.h>
#include <sched.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define MAX_EVENTS     1024
#define BUFFER_SIZE    4096
#define LISTEN_BACKLOG 1024
#define MAX_CONNS      65536

/* ---------- 每线程连接状态 ---------- */

enum conn_state {
    STATE_READ,
    STATE_WRITE,
    STATE_CLOSE,
};

struct connection {
    int             fd;
    enum conn_state state;
    char            buf[BUFFER_SIZE];
    ssize_t         buf_len;
    ssize_t         buf_sent;
};

struct worker_ctx {
    int   id;
    int   port;
    int   mode_et;        /* 1 = EPOLLET，0 = LT */
    int   threads;        /* 总线程数（用于 CPU 绑定） */
};

static volatile sig_atomic_t running = 1;

static void sig_handler(int sig)
{
    (void)sig;
    running = 0;
}

static void set_nonblocking(int fd)
{
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) { perror("fcntl F_GETFL"); exit(1); }
    if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) {
        perror("fcntl O_NONBLOCK"); exit(1);
    }
}

static int pin_to_cpu(int tid)
{
    cpu_set_t set;
    CPU_ZERO(&set);
    CPU_SET(tid, &set);
    if (sched_setaffinity(0, sizeof(set), &set) < 0) {
        fprintf(stderr, "[worker %d] warn: sched_setaffinity failed: %s\n",
                tid, strerror(errno));
        return -1;
    }
    return 0;
}

/* ---------- worker 线程主循环 ---------- */

static void *worker_loop(void *arg)
{
    struct worker_ctx *w = (struct worker_ctx *)arg;
    int listen_fd, epoll_fd;
    struct sockaddr_in addr;
    struct epoll_event ev, events[MAX_EVENTS];
    int epoll_flags;              /* EPOLLIN 或 EPOLLIN|EPOLLET */

    /* 0. CPU 亲和：线程 i 绑定 CPU i */
    pin_to_cpu(w->id);

    /* 1. 连接表：本线程独占，无需锁 */
    struct connection *conns = calloc(MAX_CONNS, sizeof(struct connection));
    if (!conns) { perror("calloc"); pthread_exit(NULL); }

    /* 2. socket + SO_REUSEPORT */
    listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_fd < 0) { perror("socket"); exit(1); }

    int optval = 1;
    if (setsockopt(listen_fd, SOL_SOCKET, SO_REUSEPORT,
                   &optval, sizeof(optval)) < 0) {
        perror("setsockopt SO_REUSEPORT"); exit(1);
    }
    setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval));

    set_nonblocking(listen_fd);

    /* 3. bind */
    memset(&addr, 0, sizeof(addr));
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port        = htons((uint16_t)w->port);

    if (bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind"); exit(1);
    }

    /* 4. listen */
    if (listen(listen_fd, LISTEN_BACKLOG) < 0) {
        perror("listen"); exit(1);
    }

    /* 5. epoll */
    epoll_fd = epoll_create1(0);
    if (epoll_fd < 0) { perror("epoll_create1"); exit(1); }

    epoll_flags = w->mode_et ? (EPOLLIN | EPOLLET) : EPOLLIN;
    ev.events  = epoll_flags;
    ev.data.fd = listen_fd;
    if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, listen_fd, &ev) < 0) {
        perror("epoll_ctl ADD listen_fd"); exit(1);
    }

    printf("[worker %d] pid=%d cpu=%d port=%d mode=%s listening ...\n",
           w->id, getpid(), sched_getcpu(), w->port,
           w->mode_et ? "EPOLLET" : "LT");

    /* 6. 事件循环
     * 注意：epoll_wait 用 100ms 超时而非 -1。
     * 原因：SIGTERM 只把 running 置 0，若无限阻塞则 worker 永远无法检查到
     * running 变化，主线程 pthread_join 会卡死，进程无法优雅退出
     * （表现为 pkill -x 用 SIGTERM 杀不掉进程，旧进程叠加监听 9988）。 */
    while (running) {
        int nfds = epoll_wait(epoll_fd, events, MAX_EVENTS, 100);
        if (nfds < 0) {
            if (errno == EINTR) continue;
            perror("epoll_wait"); break;
        }

        for (int i = 0; i < nfds; i++) {
            if (events[i].data.fd == listen_fd) {
                /* accept 循环 */
                while (1) {
                    int fd = accept(listen_fd, NULL, NULL);
                    if (fd < 0) {
                        if (errno == EAGAIN || errno == EWOULDBLOCK) break;
                        perror("accept"); break;
                    }

                    set_nonblocking(fd);
                    struct connection *c = &conns[fd];
                    c->fd       = fd;
                    c->state    = STATE_READ;
                    c->buf_len  = 0;
                    c->buf_sent = 0;

                    struct epoll_event cev;
                    cev.events   = epoll_flags;
                    cev.data.ptr = c;
                    if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &cev) < 0) {
                        perror("epoll_ctl ADD conn");
                        close(fd);
                    }
                }
            } else {
                struct connection *c = (struct connection *)events[i].data.ptr;

                if (events[i].events & (EPOLLERR | EPOLLHUP)) {
                    epoll_ctl(epoll_fd, EPOLL_CTL_DEL, c->fd, NULL);
                    close(c->fd);
                    memset(c, 0, sizeof(*c));
                    continue;
                }

                /* 状态机：READ → WRITE → READ */
                if (c->state == STATE_READ && (events[i].events & EPOLLIN)) {
                    /* ET：必须循环读到 EAGAIN 才算读空；LT：读一次等下次通知 */
                    while (1) {
                        if (c->buf_len >= (ssize_t)sizeof(c->buf)) break;
                        ssize_t n = read(c->fd,
                                         c->buf + c->buf_len,
                                         sizeof(c->buf) - c->buf_len);
                        if (n > 0) { c->buf_len += n; continue; }
                        if (n == 0) { c->state = STATE_CLOSE; break; }
                        if (errno == EAGAIN || errno == EWOULDBLOCK) break;
                        perror("read"); c->state = STATE_CLOSE; break;
                    }
                    /* LT 模式：一次 EPOLLIN 只读一批，不保证读空 */
                    if (!w->mode_et && c->state == STATE_READ &&
                        c->buf_len < (ssize_t)sizeof(c->buf)) {
                        /* 留给下一次 epoll_wait 通知 */
                    }

                    if (c->buf_len > 0 && c->state != STATE_CLOSE) {
                        c->buf_sent = 0;
                        c->state = STATE_WRITE;
                        struct epoll_event wev;
                        wev.events = w->mode_et ? (EPOLLOUT | EPOLLET) : EPOLLOUT;
                        wev.data.ptr = c;
                        epoll_ctl(epoll_fd, EPOLL_CTL_MOD, c->fd, &wev);
                    }
                }
                else if (c->state == STATE_WRITE && (events[i].events & EPOLLOUT)) {
                    while (c->buf_sent < c->buf_len) {
                        ssize_t n = write(c->fd,
                                          c->buf + c->buf_sent,
                                          c->buf_len - c->buf_sent);
                        if (n > 0) { c->buf_sent += n; continue; }
                        if (errno == EAGAIN || errno == EWOULDBLOCK) break;
                        perror("write"); c->state = STATE_CLOSE; break;
                    }

                    if (c->buf_sent >= c->buf_len) {
                        c->buf_len  = 0;
                        c->buf_sent = 0;
                        c->state    = STATE_READ;
                        struct epoll_event rev;
                        rev.events = w->mode_et ? (EPOLLIN | EPOLLET) : EPOLLIN;
                        rev.data.ptr = c;
                        epoll_ctl(epoll_fd, EPOLL_CTL_MOD, c->fd, &rev);
                    }
                }

                if (c->state == STATE_CLOSE) {
                    epoll_ctl(epoll_fd, EPOLL_CTL_DEL, c->fd, NULL);
                    close(c->fd);
                    memset(c, 0, sizeof(*c));
                }
            }
        }
    }

    close(epoll_fd);
    close(listen_fd);
    free(conns);
    return NULL;
}

/* ---------- 主程序 ---------- */

int main(int argc, char *argv[])
{
    int port    = 9988;
    int threads = 4;
    int mode_et = 1;

    if (argc > 1) port    = atoi(argv[1]);
    if (argc > 2) threads = atoi(argv[2]);
    if (argc > 3) mode_et = (strcmp(argv[3], "lt") != 0);
    if (threads < 1) threads = 1;
    if (threads > 64) threads = 64;

    signal(SIGINT,  sig_handler);
    signal(SIGTERM, sig_handler);

    printf("Master: starting %d threads (port=%d, mode=%s) ...\n",
           threads, port, mode_et ? "EPOLLET" : "LT");

    pthread_t *tids = calloc(threads, sizeof(pthread_t));
    struct worker_ctx *ctxs = calloc(threads, sizeof(struct worker_ctx));

    for (int i = 0; i < threads; i++) {
        ctxs[i].id      = i;
        ctxs[i].port    = port;
        ctxs[i].mode_et = mode_et;
        ctxs[i].threads = threads;
        if (pthread_create(&tids[i], NULL, worker_loop, &ctxs[i]) != 0) {
            perror("pthread_create"); exit(1);
        }
    }

    while (running) sleep(1);

    printf("Master: shutting down ...\n");
    for (int i = 0; i < threads; i++) {
        pthread_join(tids[i], NULL);
    }

    free(tids);
    free(ctxs);
    printf("Master: all threads stopped.\n");
    return 0;
}
