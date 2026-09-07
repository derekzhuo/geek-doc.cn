.PHONY: all clean run-lt run-epoll run-mp run-bench

CC       = gcc
CFLAGS   = -O0 -g -Wall -Wextra

all: bin/echo-epoll-lt-server bin/echo-epoll-server bin/echo-mp-server bin/echo-bench

bin/echo-epoll-lt-server: echo-epoll-lt-server.c | bin
	$(CC) $(CFLAGS) -o $@ $<

bin/echo-epoll-server: echo-epoll-server.c | bin
	$(CC) $(CFLAGS) -o $@ $<

bin/echo-mp-server: echo-mp-server.c | bin
	$(CC) $(CFLAGS) -o $@ $<

bin/echo-bench: echo-bench.c | bin
	$(CC) $(CFLAGS) -o $@ $<

bin:
	mkdir -p bin

# 终端1: 启动 LT 水平触发版服务端
run-lt: bin/echo-epoll-lt-server
	./bin/echo-epoll-lt-server

# 终端2: 启动 ET 边缘触发版服务端
run-epoll: bin/echo-epoll-server
	./bin/echo-epoll-server

# 终端3: 启动多进程版服务端（4 个 worker）
run-mp: bin/echo-mp-server
	./bin/echo-mp-server 4

# 终端4: 压测
run-bench-lt: bin/echo-bench
	./bin/echo-bench 127.0.0.1 9988 100 1

run-bench-epoll: bin/echo-bench
	./bin/echo-bench 127.0.0.1 9988 100 1

run-bench-mp: bin/echo-bench
	./bin/echo-bench 127.0.0.1 9988 100 10

bench: bin/echo-bench
	bash bench.sh 127.0.0.1 9988 100

# 一键重跑全部实验（约 15-20 分钟）
# 可选参数: --short | --long | --bench-sh | --sweep | --strace
run-all:
	bash run_all.sh

run-all-short:
	bash run_all.sh --short

run-all-long:
	bash run_all.sh --long

clean:
	rm -rf bin results_*
