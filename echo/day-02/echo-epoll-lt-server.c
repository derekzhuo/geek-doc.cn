/*
 * echo-epoll-lt-server.c — epoll 水平触发（EPOLLLT）+ 非阻塞 IO
 *
 * 与 echo-epoll-server.c 功能完全一致，但使用 LT（Level-Triggered，水平触发）
 * 而非 ET（Edge-Triggered，边缘触发）。
 *
 * LT vs ET 的核心差异：
 *   LT（默认）：只要 fd 仍然可读/可写，每次 epoll_wait 都会返回该事件
 *   ET：只在 fd 状态从不可读→可读、或不可写→可写时通知一次
 *
 * LT 编程范式：
 *   - accept() 可以只取一个（下次 epoll_wait 还会通知）
 *   - read() 可以只读一次（没读完的数据下次还触发 EPOLLIN）
 *   - write() 可以只写一次（没写完下次还触发 EPOLLOUT）
 *   - 状态切换时仍需 epoll_ctl(MOD)——LT 只持续通知"已注册的事件类型"，
 *     不注册 EPOLLOUT 就不会收到可写通知；写完后不切回 EPOLLIN 会导致空转
 *
 * 代价：
 *   - 更多 epoll_wait 唤醒次数（每次循环都要唤醒确认 fd 状态）
 *   - 在高并发场景下可能被"惊群"式唤醒浪费 CPU
 *   - 缓冲区始终"可写"时（对端接收窗口大）会反复触发 EPOLLOUT
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
    int             fd;
    enum conn_state state;
    char            buf[BUFFER_SIZE];
    ssize_t         buf_len;       /* 当前 buf 中已读到的字节数 */
    ssize_t         buf_sent;      /* 已经写回的字节数（处理部分写） */
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

/* ---------- 事件处理（LT 范式）---------- */

/*
 * LT 下的 accept：可以只取一个连接。
 *
 * 与 ET 版的关键差异：ET 必须循环 accept 到 EAGAIN，否则剩余连接丢失；
 * LT 下如果只 accept 一个，下次 epoll_wait 还会收到 EPOLLIN on listen_fd，
 * 所以不循环也可以正常工作。
 *
 * 但这里仍然循环 accept——因为一次性取完多个连接比多次 epoll_wait 高效。
 */
static void handle_accept(int epoll_fd, int listen_fd)
{
    /* LT 下可以不循环，但循环更高效（减少 epoll_wait 次数） */
    while (1) {
        int fd = accept(listen_fd, NULL, NULL);
        if (fd < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK)
                break;
            perror("accept");
            break;
        }

        set_nonblocking(fd);
        conn_init(&conns[fd], fd);

        struct epoll_event ev;
        /*
         * LT 关键点：不需要 EPOLLET 标志。
         * 如果不用 EPOLLET，epoll 默认就是 LT 模式。
         *
         * 初始只注册 EPOLLIN——accept 后连接处于 STATE_READ。
         * 后续状态切换时需要 epoll_ctl(MOD)：
         *   STATE_READ → STATE_WRITE：切换为 EPOLLOUT
         *   STATE_WRITE → STATE_READ：切换为 EPOLLIN
         * 原因：LT 只持续通知"已注册的事件"，不注册 EPOLLOUT 就不会通知可写。
         */
        ev.events   = EPOLLIN;   /* LT 默认，不写 EPOLLET */
        ev.data.ptr = &conns[fd];
        if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &ev) < 0) {
            perror("epoll_ctl ADD");
            close(fd);
            continue;
        }

        printf("new connection fd=%d (LT mode)\n", fd);
    }
}

/*
 * LT 下的 read：可以只读一次。
 *
 * 与 ET 版的关键差异：
 *   ET 下如果不循环读到 EAGAIN，剩余数据再也不会触发 EPOLLIN → 数据永久丢失
 *   LT 下读了一次（哪怕只读了 1 字节），只要内核缓冲区还有数据，
 *   下次 epoll_wait 还会返回 EPOLLIN → 不会丢数据
 *
 * 但这里仍然循环读——原因同 accept：一次性读完比多次 epoll_wait 高效。
 */
static void handle_read(int epoll_fd, struct connection *c)
{
    /*
     * LT 范式：可以不循环，只读一次就返回。
     * 没读完的数据下次 EPOLLIN 还会触发。
     *
     * 但为了减少 epoll_wait 唤醒次数（性能考虑），这里仍然循环读。
     */
    while (1) {
        if (c->buf_len >= (ssize_t)sizeof(c->buf)) {
            c->state = STATE_WRITE;
            return;
        }

        ssize_t n = read(c->fd,
                         c->buf + c->buf_len,
                         sizeof(c->buf) - c->buf_len);
        if (n > 0) {
            c->buf_len += n;
            continue;
        }

        if (n == 0) {
            c->state = STATE_CLOSE;
            return;
        }

        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            if (c->buf_len > 0) {
                c->buf_sent = 0;
                c->state = STATE_WRITE;
                struct epoll_event ev;
                ev.events   = EPOLLOUT;   /* LT 模式，不写 EPOLLET */
                ev.data.ptr = c;
                epoll_ctl(epoll_fd, EPOLL_CTL_MOD, c->fd, &ev);
            }
            return;
        }

        perror("read");
        c->state = STATE_CLOSE;
        return;
    }
}

/*
 * LT 下的 write：可以只写一次。
 *
 * 与 ET 版的关键差异：
 *   ET 下如果部分写了，必须手动 epoll_ctl(MOD, EPOLLOUT) 等待下次通知；
 *   LT 下如果部分写了，只要连接仍可写，epoll_wait 会持续返回 EPOLLOUT。
 *
 * LT 的陷阱：如果对端接收窗口一直很大（例如对端也在高速读取），
 * 内核发送缓冲区几乎始终可写 → epoll_wait 每次都返回 EPOLLOUT
 * → 空转消耗 CPU。这是 LT 下 EPOLLOUT 的经典问题：
 * "只在需要写的时候才注册 EPOLLOUT，写完了就取消"。
 *
 * 当前实现采用 ET 版同样的策略：循环写到 EAGAIN 或全部写完，
 * 然后通过状态机决定是否注册 EPOLLOUT。
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
            return;
        }

        perror("write");
        c->state = STATE_CLOSE;
        return;
    }

    /* 全部写完 → 清空 buf，切回读状态 */
    c->buf_len  = 0;
    c->buf_sent = 0;
    c->state    = STATE_READ;

    struct epoll_event ev;
    ev.events   = EPOLLIN;   /* LT 模式，不写 EPOLLET */
    ev.data.ptr = c;
    epoll_ctl(epoll_fd, EPOLL_CTL_MOD, c->fd, &ev);
}

/* ---------- 主程序 ---------- */

int main(void)
{
    int listen_fd, epoll_fd;
    struct sockaddr_in addr;
    struct epoll_event ev, events[MAX_EVENTS];

    /* 1. 分配连接表 */
    int max_fds = 65536;
    conns = calloc(max_fds, sizeof(struct connection));
    if (!conns) { perror("calloc"); exit(1); }

    /* 2. socket */
    listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_fd < 0) { perror("socket"); exit(1); }

    int reuse = 1;
    setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));

    set_nonblocking(listen_fd);

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

    /*
     * LT 关键点：listen_fd 也注册为 LT（默认，不写 EPOLLET）。
     * LT 下 Accept 队列有连接时，每次 epoll_wait 都返回 EPOLLIN。
     */
    ev.events   = EPOLLIN;   /* LT 默认 */
    ev.data.fd  = listen_fd;
    if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, listen_fd, &ev) < 0) {
        perror("epoll_ctl ADD listen_fd"); exit(1);
    }

    printf("Epoll echo server (single-process, LT/Level-Triggered) listening on port %d ...\n", PORT);

    /*
     * 6. 事件循环（LT 模式）
     *
     * 与 ET 版的关键差异：
     *   - LT 不需要循环读到 EAGAIN（不循环也不会丢数据）
     *   - 但状态机仍要 epoll_ctl(MOD) 切换 EPOLLIN/EPOLLOUT
     *     否则：读完数据切 STATE_WRITE 后，epoll 不会通知 EPOLLOUT → 写永远不触发
     *   - 同时写完切 STATE_READ 后，也要切回 EPOLLIN，否则 EPOLLOUT 持续触发空转
     *
     * 状态机设计保证了 STATE_READ 时只注册 EPOLLIN，STATE_WRITE 时只注册 EPOLLOUT，
     * 所以 events 和状态始终匹配。
     */
    while (1) {
        int nfds = epoll_wait(epoll_fd, events, MAX_EVENTS, -1);
        if (nfds < 0) {
            if (errno == EINTR) continue;
            perror("epoll_wait"); break;
        }

        for (int i = 0; i < nfds; i++) {
            if (events[i].data.fd == listen_fd) {
                handle_accept(epoll_fd, listen_fd);
            } else {
                struct connection *c = (struct connection *)events[i].data.ptr;

                if (events[i].events & (EPOLLERR | EPOLLHUP)) {
                    conn_close(epoll_fd, c);
                    continue;
                }

                /*
                 * LT 核心差异：事件分发的简化
                 *
                 * ET 版必须在 switch(c->state) 中精确匹配状态与事件类型，
                 * 因为 ET 只通知一次，状态和事件必须严格对应。
                 *
                 * LT 版可以更宽松——即使状态判断有偏差，下次 epoll_wait
                 * 还会再通知，不会丢数据。但我们仍然保持状态机以确保正确性。
                 */
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
