#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <sys/signalfd.h>
#include <sys/epoll.h>
#include <sys/wait.h>

#define MAX_EVENTS 64

int main(void)
{
    // 1. 屏蔽要处理的信号 —— signalfd 要求这些信号必须被 block
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGTERM);
    sigaddset(&mask, SIGINT);
    sigaddset(&mask, SIGCHLD);
    sigprocmask(SIG_BLOCK, &mask, NULL);

    // 2. 创建 signalfd —— 信号从此变成 fd
    int sfd = signalfd(-1, &mask, SFD_NONBLOCK | SFD_CLOEXEC);
    if (sfd < 0) { perror("signalfd"); exit(1); }

    // 3. 把 sfd 加入 epoll —— 和业务 fd 统一调度
    int epfd = epoll_create1(0);
    struct epoll_event ev;
    ev.events = EPOLLIN;
    ev.data.fd = sfd;
    epoll_ctl(epfd, EPOLL_CTL_ADD, sfd, &ev);

    printf("server running, pid=%d, send 'kill %d' to stop\n", getpid(), getpid());

    volatile sig_atomic_t running = 1;
    struct epoll_event events[MAX_EVENTS];
    while (running) {
        int n = epoll_wait(epfd, events, MAX_EVENTS, -1);
        if (n < 0) {
            if (errno == EINTR) continue;  // 即使 SA_RESTART 也会 EINTR (坑五)
            perror("epoll_wait");
            break;
        }
        for (int i = 0; i < n; i++) {
            if (events[i].data.fd == sfd) {
                struct signalfd_siginfo si;
                ssize_t r = read(sfd, &si, sizeof(si));
                if (r != sizeof(si)) continue;
                printf("got signal %d (from pid %d)\n", si.ssi_signo, si.ssi_pid);
                if (si.ssi_signo == SIGTERM || si.ssi_signo == SIGINT) {
                    // ★ 主循环里可以随便调函数做优雅停机:
                    // 关监听 fd → 排干在途请求 → 刷日志 → 停 worker
                    printf("graceful shutdown...\n");
                    running = 0;
                }
            }
        }
    }
    close(sfd);
    close(epfd);
    printf("bye\n");
    return 0;
}

