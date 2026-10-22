#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <string.h>

static void alarm_handler(int sig)
{
    /* 什么都不用做 —— 目的只是打断阻塞的 read() */
}

int read_with_timeout(int fd, char *buf, size_t len, int seconds)
{
    // 1. 注册 handler: 注意不要 SA_RESTART! 否则 read 会被自动重启(坑五)
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = alarm_handler;   // 故意不设 SA_RESTART
    sigemptyset(&sa.sa_mask);
    sigaction(SIGALRM, &sa, NULL);

    // 2. 设闹钟
    alarm(seconds);

    // 3. read —— 超时会被 SIGALRM 打断返回 EINTR
    ssize_t n = read(fd, buf, len);

    // 4. 关闹钟(若已读满提前返回), 清除可能残留的 SIGALRM
    alarm(0);

    if (n < 0 && errno == EINTR) {
        fprintf(stderr, "read timed out after %d sec\n", seconds);
        return -1;  // 超时
    }
    return (int)n;  // 成功读到的字节数
}

int main(void)
{
    char buf[128];
    printf("type something within 3 seconds (pipe/terminal):\n");
    int n = read_with_timeout(STDIN_FILENO, buf, sizeof(buf), 3);
    if (n > 0) printf("read %d bytes: %.*s\n", n, n, buf);
    return 0;
}

