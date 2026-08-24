/*
 * echo-mp-server.c — 多进程 + SO_REUSEPORT + 每进程独立 epoll
 *
 * 每个 worker 进程独立完成 socket/bind/listen/epoll，
 * 利用 SO_REUSEPORT 让内核把新连接**均匀分发**到各进程的 listen 队列。
 *
 * 设计意图：
 *   1. 隔离性：一个进程崩溃不影响其他进程
 *   2. 缓存亲和：每个进程粘在一组 CPU 核上，L1/L2 缓存命中率高
 *   3. 为后续 NUMA 拆分（day-06）埋基础
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define PORT           9988
#define MAX_EVENTS     1024
#define BUFFER_SIZE    4096
#define LISTEN_BACKLOG 128
#define NUM_WORKERS    4         /* 默认 worker 进程数 */

/* ---------- 工具函数 ---------- */

static void set_nonblocking(int fd)
{
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) { perror("fcntl F_GETFL"); exit(1); }
    if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) {
        perror("fcntl O_NONBLOCK"); exit(1);
    }
}

/* ---------- 每个连接的状态 ---------- */

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

/* ---------- worker 进程的主循环 ---------- */

static void worker_loop(int worker_id)
{
    int listen_fd, epoll_fd;
    struct sockaddr_in addr;
    struct epoll_event ev, events[MAX_EVENTS];

    struct connection *conns = calloc(65536, sizeof(struct connection));
    if (!conns) { perror("calloc"); exit(1); }

    /* 1. socket + SO_REUSEPORT */
    listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_fd < 0) { perror("socket"); exit(1); }

    int optval = 1;
    if (setsockopt(listen_fd, SOL_SOCKET, SO_REUSEPORT,
                   &optval, sizeof(optval)) < 0) {
        perror("setsockopt SO_REUSEPORT"); exit(1);
    }
    setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval));

    set_nonblocking(listen_fd);

    /* 2. bind */
    memset(&addr, 0, sizeof(addr));
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port        = htons(PORT);

    if (bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind"); exit(1);
    }

    /* 3. listen */
    if (listen(listen_fd, LISTEN_BACKLOG) < 0) {
        perror("listen"); exit(1);
    }

    /* 4. epoll */
    epoll_fd = epoll_create1(0);
    if (epoll_fd < 0) { perror("epoll_create1"); exit(1); }

    ev.events  = EPOLLIN | EPOLLET;
    ev.data.fd = listen_fd;
    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, listen_fd, &ev);

    printf("[worker %d] pid=%d, listening on port %d\n",
           worker_id, getpid(), PORT);

    /* 5. 事件循环（与 echo-epoll-server 一致） */
    while (1) {
        int nfds = epoll_wait(epoll_fd, events, MAX_EVENTS, -1);
        if (nfds < 0) {
            if (errno == EINTR) continue;
            perror("epoll_wait"); break;
        }

        for (int i = 0; i < nfds; i++) {
            if (events[i].data.fd == listen_fd) {
                /* accept 循环（边缘触发必须循环到 EAGAIN） */
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
                    cev.events   = EPOLLIN | EPOLLET;
                    cev.data.ptr = c;
                    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &cev);
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
                    /* 循环读到 EAGAIN */
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

                    if (c->buf_len > 0 && c->state != STATE_CLOSE) {
                        c->buf_sent = 0;
                        c->state = STATE_WRITE;
                        struct epoll_event wev;
                        wev.events   = EPOLLOUT | EPOLLET;
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
                        /* 写完，切回读 */
                        c->buf_len  = 0;
                        c->buf_sent = 0;
                        c->state    = STATE_READ;
                        struct epoll_event rev;
                        rev.events   = EPOLLIN | EPOLLET;
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
}

/* ---------- 主进程：fork workers + 收割僵尸 ---------- */

static volatile sig_atomic_t running = 1;

static void sig_handler(int sig)
{
    (void)sig;
    running = 0;
}

int main(int argc, char *argv[])
{
    int num_workers = NUM_WORKERS;
    if (argc > 1) num_workers = atoi(argv[1]);
    if (num_workers < 1) num_workers = 1;

    /* 信号处理：优雅退出 */
    signal(SIGINT,  sig_handler);
    signal(SIGTERM, sig_handler);
    signal(SIGCHLD, SIG_DFL);   /* 子进程退出用 waitpid 收割 */

    printf("Master pid=%d, starting %d workers ...\n", getpid(), num_workers);

    pid_t *children = calloc(num_workers, sizeof(pid_t));

    for (int i = 0; i < num_workers; i++) {
        pid_t pid = fork();
        if (pid < 0) {
            perror("fork"); exit(1);
        }

        if (pid == 0) {
            /* 子进程：进入事件循环 */
            free(children);
            worker_loop(i);
            exit(0);
        }

        children[i] = pid;
    }

    printf("Master: all %d workers started, waiting ...\n", num_workers);

    /* 主进程：等子进程退出，收割僵尸 */
    while (running) {
        int status;
        pid_t pid = waitpid(-1, &status, WNOHANG);
        if (pid > 0) {
            printf("Master: worker pid=%d exited (status=%d)\n",
                   pid, WEXITSTATUS(status));
            /* 生产环境应该在这里重新 fork 一个 */
        }
        sleep(1);
    }

    /* 退出时杀掉所有子进程 */
    printf("Master: shutting down workers ...\n");
    for (int i = 0; i < num_workers; i++) {
        if (children[i] > 0) kill(children[i], SIGTERM);
    }
    /* 等子进程全部退出 */
    for (int i = 0; i < num_workers; i++) {
        if (children[i] > 0) waitpid(children[i], NULL, 0);
    }

    free(children);
    printf("Master: all workers stopped.\n");
    return 0;
}
