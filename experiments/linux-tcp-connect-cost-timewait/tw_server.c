/*
 * 短连接对照实验服务端：回完 HTTP 响应后故意延迟关闭，
 * 让客户端先发出 FIN、成为主动关闭方，TIME_WAIT 因此落在客户端侧的临时端口上。
 */
#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#define PORT 18080
#define LINGER_MS 500

static const char RESP[] =
    "HTTP/1.0 200 OK\r\n"
    "Content-Type: text/plain\r\n"
    "Content-Length: 3\r\n"
    "Connection: close\r\n"
    "\r\n"
    "ok\n";

static void *handle(void *arg)
{
    int fd = (int)(long)arg;
    char buf[512];
    (void)recv(fd, buf, sizeof(buf), 0);
    (void)send(fd, RESP, sizeof(RESP) - 1, 0);
    /* 不 shutdown、不立即 close：等客户端先 FIN，服务端始终是被动关闭方 */
    usleep(LINGER_MS * 1000);
    close(fd);
    return NULL;
}

int main(void)
{
    int lfd = socket(AF_INET, SOCK_STREAM, 0);
    if (lfd < 0) { perror("socket"); return 1; }
    int one = 1;
    setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = htons(PORT);
    if (bind(lfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind"); return 1;
    }
    if (listen(lfd, 1024) < 0) { perror("listen"); return 1; }
    printf("tw_server listening on 127.0.0.1:%d, linger=%dms\n",
           PORT, LINGER_MS);

    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    for (;;) {
        int cfd = accept(lfd, NULL, NULL);
        if (cfd < 0) {
            /* EMFILE/ENFILE：突发把进程 fd 打满，关掉一个陈旧连接腾位后继续；
             * 这类压力下不逐条 perror，避免错误日志本身把磁盘写满 */
            if (errno == EMFILE || errno == ENFILE) {
                int salvage = accept(lfd, NULL, NULL);
                if (salvage >= 0) close(salvage);
                usleep(1000);
                continue;
            }
            if (errno == EINTR) continue;
            perror("accept"); continue;
        }
        pthread_t tid;
        if (pthread_create(&tid, &attr, handle, (void *)(long)cfd) != 0) {
            close(cfd);
        }
    }
}
