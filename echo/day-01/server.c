/*
 * server.c — 最简 TCP Echo 服务端
 * 阻塞IO，单进程，一次只处理一个连接
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define PORT         9090
#define BUFFER_SIZE  4096

int main(void)
{
    int listen_fd, conn_fd;
    struct sockaddr_in addr;
    char buf[BUFFER_SIZE];
    ssize_t n;

    /* 1. 创建 socket */
    listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_fd < 0) {
        perror("socket");
        exit(1);
    }

    /* 2. bind */
    memset(&addr, 0, sizeof(addr));
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port        = htons(PORT);

    if (bind(listen_fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind");
        exit(1);
    }

    /* 3. listen */
    if (listen(listen_fd, 10) < 0) {
        perror("listen");
        exit(1);
    }

    printf("Echo server listening on port %d ...\n", PORT);

    /* 4. 主循环：逐个 accept → read → write → close */
    while (1) {
        conn_fd = accept(listen_fd, NULL, NULL);
        if (conn_fd < 0) {
            perror("accept");
            continue;
        }

        printf("new connection fd=%d\n", conn_fd);

        while ((n = read(conn_fd, buf, sizeof(buf))) > 0) {
            write(conn_fd, buf, n);
        }

        close(conn_fd);
        printf("connection fd=%d closed\n", conn_fd);
    }

    close(listen_fd);
    return 0;
}
