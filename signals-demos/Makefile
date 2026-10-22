# Makefile for signals-demos —— 信号用户态编程五连击
# 对应文档: concepts/process/task-resources/signals-user-demos.md
#
# demo1: signalfd + epoll 优雅退出
# demo2: alarm + EINTR 超时
# demo3: sigwait 专用线程
# demo4: signalfd 完整集成（SIGHUP 重载 + 优雅停机）
# demo5: SIGSEGV backtrace（SA_SIGINFO + SA_ONSTACK）

CC     := gcc
CFLAGS := -O2 -Wall
DEMOS  := sfd_demo alarm_demo sigwait_demo sfd_epoll_demo segv_backtrace

.PHONY: all run run1 run2 run3 run4 run5 clean

all: $(DEMOS)

sfd_demo: sfd_demo.c
	$(CC) $(CFLAGS) -o $@ $<

alarm_demo: alarm_demo.c
	$(CC) $(CFLAGS) -o $@ $<

sigwait_demo: sigwait_demo.c
	$(CC) $(CFLAGS) -pthread -o $@ $<

sfd_epoll_demo: sfd_epoll_demo.c
	$(CC) $(CFLAGS) -o $@ $<

segv_backtrace: segv_backtrace.c
	$(CC) $(CFLAGS) -g -O0 -rdynamic -o $@ $<

run: all
	@echo "== demo1: signalfd + epoll 优雅退出 =="; ./sfd_demo & sleep 0.2; kill -TERM %1; wait %1
	@echo "== demo2: alarm 超时（不输入,3 秒后超时）=="; echo "" | ./alarm_demo
	@echo "== demo3: sigwait 专用线程 =="; ./sigwait_demo & sleep 0.2; kill -TERM %1; wait %1
	@echo "== demo4: signalfd 完整集成 =="; ./sfd_epoll_demo & sleep 0.2; kill -HUP %1; sleep 0.2; kill -TERM %1; wait %1
	@echo "== demo5: SIGSEGV backtrace =="; ./segv_backtrace 2>&1 || true

run1: sfd_demo; ./sfd_demo
run2: alarm_demo; ./alarm_demo
run3: sigwait_demo; ./sigwait_demo
run4: sfd_epoll_demo; ./sfd_epoll_demo
run5: segv_backtrace; ./segv_backtrace

clean:
	rm -f $(DEMOS)
