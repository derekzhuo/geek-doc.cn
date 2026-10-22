#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <sys/signalfd.h>
#include <sys/epoll.h>

static volatile sig_atomic_t reload_config = 0;

static void handle_signal(struct signalfd_siginfo *si)
{
    switch (si->ssi_signo) {
    case SIGTERM:
    case SIGINT:
        printf("[event loop] got %s, shutting down\n",
               si->ssi_signo == SIGTERM ? "SIGTERM" : "SIGINT");
        exit(0);                       /* 优雅停机: 主循环退出 */
        break;
    case SIGHUP:
        printf("[event loop] SIGHUP: reloading config...\n");
        reload_config = 1;             /* 设置标志, 主循环里再加载 */
        break;
    case SIGUSR1:
        printf("[event loop] SIGUSR1 (custom signal)\n");
        break;
    default:
        printf("[event loop] unhandled signal %d\n", si->ssi_signo);
        break;
    }
}

int main(void)
{
    sigset_t mask;
    sigemptyset(&mask);
    sigaddset(&mask, SIGTERM);
    sigaddset(&mask, SIGINT);
    sigaddset(&mask, SIGHUP);
    sigaddset(&mask, SIGUSR1);
    sigaddset(&mask, SIGCHLD);
    sigprocmask(SIG_BLOCK, &mask, NULL);          /* 先 block 再 signalfd */

    int sfd = signalfd(-1, &mask, SFD_NONBLOCK | SFD_CLOEXEC);
    if (sfd < 0) { perror("signalfd"); return 1; }

    int epfd = epoll_create1(0);
    struct epoll_event ev = { .events = EPOLLIN, .data.fd = sfd };
    epoll_ctl(epfd, EPOLL_CTL_ADD, sfd, &ev);

    printf("server pid=%d\n", getpid());
    struct epoll_event events[16];
    while (1) {
        int n = epoll_wait(epfd, events, 16, -1);
        if (n < 0) { if (errno == EINTR) continue; perror("epoll_wait"); break; }
        for (int i = 0; i < n; i++) {
            if (events[i].data.fd == sfd) {
                struct signalfd_siginfo si;
                while (read(sfd, &si, sizeof(si)) == sizeof(si))
                    handle_signal(&si);            /* 一次性读光所有信号 */
            }
            /* 其余 fd 的 EPOLLIN 处理在这里 */
        }
        if (reload_config) {
            reload_config = 0;
            /* 真正重载配置: 读文件 → 换配置结构 → 广播通知 */
        }
    }
}

