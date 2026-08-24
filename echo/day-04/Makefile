.PHONY: all clean run-mt run-mt-lt bench test-env

CC       = gcc
CFLAGS   = -O0 -g -Wall -Wextra -pthread

# 复用 day-03 的并行压测客户端（同一把尺子）
KP_BENCH_SRC = ../day-03/echo-kp-bench.c

all: bin/echo-mt-server bin/echo-kp-bench

bin/echo-mt-server: echo-mt-server.c | bin
	$(CC) $(CFLAGS) -o $@ $<

bin/echo-kp-bench: $(KP_BENCH_SRC) | bin
	$(CC) -O0 -g -Wall -Wextra -pthread -o $@ $<

bin:
	mkdir -p bin

# 终端1: 启动 4 线程 ET 边缘触发服务端（默认）
run-mt: bin/echo-mt-server
	./bin/echo-mt-server 9988 4 et

# 终端1: 启动 4 线程 LT 水平触发服务端
run-mt-lt: bin/echo-mt-server
	./bin/echo-mt-server 9988 4 lt

# 压测：短连接 / 长连接，100 并发 × 10 轮
bench-short: bin/echo-kp-bench
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode short

bench-long: bin/echo-kp-bench
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode long

# 环境自检
test-env:
	@echo "nproc = $$(nproc)"; ulimit -n; \
	sysctl net.ipv4.tcp_tw_reuse net.ipv4.tcp_fin_timeout

clean:
	rm -rf bin results_*
