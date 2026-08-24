/*
 * echo-epoll-server.c — epoll 边缘触发（EPOLLET）+ 非阻塞 IO
 *
 * 单进程，epoll 管理所有 fd（listen_fd + 所有 client_fd）。
 * EPOLLET 意味着每个 fd 只通知一次状态变化，必须循环读到 EAGAIN
 * 才算把数据读空——否则后续数据不再触发事件，连接卡死。
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define PORT          9988
#define MAX_EVENTS    1024
#define BUFFER_SIZE   4096
#define LISTEN_BACKLOG 128

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
    STATE_READ,        /* 等待读 */
    STATE_WRITE,       /* 有数据待写回 */
    STATE_CLOSE,       /* 对端已关闭 */
};

struct connection {
    int           fd;
    enum conn_state state;
    char          buf[BUFFER_SIZE];
    ssize_t       buf_len;       /* 当前 buf 中已读到的字节数 */
    ssize_t       buf_sent;      /* 已经写回的字节数（处理部分写） */
};

/* ---------- 全局 ---------- */

static struct connection *conns;     /* fd → connection 查表，fd 作下标 */

static void conn_init(struct connection *c, int fd)
{
    c->fd       = fd;
    c->state    = STATE_READ;
    c->buf_len  = 0;
    c->buf_sent = 0;
}

static void conn_close(int epoll_fd, struct connection *c)
{
    printf("connection fd=%d closed\n", c->fd);
    epoll_ctl(epoll_fd, EPOLL_CTL_DEL, c->fd, NULL);
    close(c->fd);
    memset(c, 0, sizeof(*c));
}

/* ---------- 事件处理 ---------- */

/*
 * accept 新连接。EPOLLET 下必须在循环里 accept 到 EAGAIN，
 * 否则当多个连接同时到达时，只 accept 了一个，剩下的会丢失。
 */
static void handle_accept(int epoll_fd, int listen_fd)
{
    while (1) {
        int fd = accept(listen_fd, NULL, NULL);
        if (fd < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK)
                break;   /* 没有更多连接了，正常 */
            perror("accept");
            break;
        }

        set_nonblocking(fd);
        conn_init(&conns[fd], fd);

        struct epoll_event ev;
        ev.events   = EPOLLIN | EPOLLET;   /* 边沿触发：只通知一次 */
        ev.data.ptr = &conns[fd];
        if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &ev) < 0) {
            perror("epoll_ctl ADD");
            close(fd);
            continue;
        }

        printf("new connection fd=%d\n", fd);
    }
}

/*
 * EPOLLET 下必须循环 read 到 EAGAIN。
 * 每次读到数据就追加到 conn->buf，读完切到写状态。
 */
static void handle_read(int epoll_fd, struct connection *c)
{
    while (1) {
        /* 缓冲区保护：如果已满就切去写 */
        if (c->buf_len >= (ssize_t)sizeof(c->buf)) {
            c->state = STATE_WRITE;
            struct epoll_event ev;
            ev.events   = EPOLLOUT | EPOLLET;
            ev.data.ptr = c;
            epoll_ctl(epoll_fd, EPOLL_CTL_MOD, c->fd, &ev);
            return;
        }

        ssize_t n = read(c->fd,
                         c->buf + c->buf_len,
                         sizeof(c->buf) - c->buf_len);
        if (n > 0) {
            c->buf_len += n;
            continue;   /* 继续读，直到 EAGAIN */
        }

        if (n == 0) {
            /* 对端关闭（FIN） */
            c->state = STATE_CLOSE;
            return;
        }

        /* n < 0 */
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            /* 读空了，切到写状态 */
            if (c->buf_len > 0) {
                c->buf_sent = 0;
                c->state = STATE_WRITE;
                struct epoll_event ev;
                ev.events   = EPOLLOUT | EPOLLET;
                ev.data.ptr = c;
                epoll_ctl(epoll_fd, EPOLL_CTL_MOD, c->fd, &ev);
            }
            /* 没数据 → 继续等读 */
            return;
        }

        /* 真正的错误 */
        perror("read");
        c->state = STATE_CLOSE;
        return;
    }
}

/*
 * EPOLLOUT：把 buf 中剩余数据写回客户端。
 * EPOLLET 下也要循环 write 到 EAGAIN（处理部分写）。
 */
static void handle_write(int epoll_fd, struct connection *c)
{
    while (c->buf_sent < c->buf_len) {
        ssize_t n = write(c->fd,
                          c->buf + c->buf_sent,
                          c->buf_len - c->buf_sent);
        if (n > 0) {
            c->buf_sent += n;
            continue;
        }

        if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            /* 写缓冲区满了，等下次 EPOLLOUT */
            return;
        }

        /* write 出错 */
        perror("write");
        c->state = STATE_CLOSE;
        return;
    }

    /* 全部写完 → 清空 buf，切回读状态 */
    c->buf_len  = 0;
    c->buf_sent = 0;
    c->state    = STATE_READ;

    struct epoll_event ev;
    ev.events   = EPOLLIN | EPOLLET;
    ev.data.ptr = c;
    epoll_ctl(epoll_fd, EPOLL_CTL_MOD, c->fd, &ev);
}

/* ---------- 主程序 ---------- */

int main(void)
{
    int listen_fd, epoll_fd;
    struct sockaddr_in addr;
    struct epoll_event ev, events[MAX_EVENTS];

    /* 1. 分配连接表：fd 最大不超过 ulimit -n */
    int max_fds = 65536;
    conns = calloc(max_fds, sizeof(struct connection));
    if (!conns) { perror("calloc"); exit(1); }

    /* 2. socket */
    listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_fd < 0) { perror("socket"); exit(1); }

    int reuse = 1;
    setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));

    set_nonblocking(listen_fd);     /* 必须非阻塞！ */

    /* 3. bind */
    memset(&addr, 0, sizeof(addr));
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port        = htons(PORT);

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

    ev.events   = EPOLLIN | EPOLLET;  /* 监听连接也是边沿触发 */
    ev.data.fd  = listen_fd;
    if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, listen_fd, &ev) < 0) {
        perror("epoll_ctl ADD listen_fd"); exit(1);
    }

    printf("Epoll echo server (single-process, EPOLLET) listening on port %d ...\n", PORT);

    /* 6. 事件循环 */
    while (1) {
        int nfds = epoll_wait(epoll_fd, events, MAX_EVENTS, -1);
        if (nfds < 0) {
            if (errno == EINTR) continue;
            perror("epoll_wait"); break;
        }

        for (int i = 0; i < nfds; i++) {
            if (events[i].data.fd == listen_fd) {
                /* 新连接 */
                handle_accept(epoll_fd, listen_fd);
            } else {
                struct connection *c = (struct connection *)events[i].data.ptr;

                /* 对端关闭或出错 */
                if (events[i].events & (EPOLLERR | EPOLLHUP)) {
                    conn_close(epoll_fd, c);
                    continue;
                }

                /* 状态机驱动 */
                switch (c->state) {
                case STATE_READ:
                    if (events[i].events & EPOLLIN)
                        handle_read(epoll_fd, c);
                    break;
                case STATE_WRITE:
                    if (events[i].events & EPOLLOUT)
                        handle_write(epoll_fd, c);
                    break;
                default:
                    break;
                }

                /* 读取/写入过程中发现对端关闭 */
                if (c->state == STATE_CLOSE)
                    conn_close(epoll_fd, c);
            }
        }
    }

    close(epoll_fd);
    close(listen_fd);
    free(conns);
    return 0;
}
