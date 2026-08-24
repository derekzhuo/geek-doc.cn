/*
 * client.c — 最简 TCP Echo 客户端
 * 连接 → 发送一条消息 → 接收回复 → 打印 → 退出
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define BUFFER_SIZE 4096

int main(int argc, char *argv[])
{
    const char *server_ip   = (argc > 1) ? argv[1] : "127.0.0.1";
    int         server_port = (argc > 2) ? atoi(argv[2]) : 9090;
    int         fd;
    struct sockaddr_in addr;
    char        buf[BUFFER_SIZE];
    const char *msg = "hello echo";
    ssize_t     n;

    /* 1. 创建 socket */
    fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
        perror("socket");
        exit(1);
    }

    /* 2. connect */
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(server_port);
    if (inet_pton(AF_INET, server_ip, &addr.sin_addr) <= 0) {
        perror("inet_pton");
        exit(1);
    }

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("connect");
        exit(1);
    }

    printf("Connected to %s:%d\n", server_ip, server_port);

    /* 3. 发送 */
    n = write(fd, msg, strlen(msg));
    printf("Sent: %.*s (%zd bytes)\n", (int)n, msg, n);

    /* 4. 接收 */
    n = read(fd, buf, sizeof(buf) - 1);
    if (n > 0) {
        buf[n] = '\0';
        printf("Received: %s (%zd bytes)\n", buf, n);
    } else {
        perror("read");
    }

    close(fd);
    return 0;
}
