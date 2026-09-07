.PHONY: all clean bench run-lt run-et \
        bench-short bench-long bench-scale \
        bench-lt-short bench-lt-long bench-et-short bench-et-long \
        strace-lt-short strace-lt-long

CC      = gcc
CFLAGS  = -O2 -g -Wall -Wextra
LDFLAGS = -lpthread

BIN_DIR = bin
DAY02   = ../day-02

all: $(BIN_DIR)/echo-kp-bench $(BIN_DIR)/echo-epoll-lt-server $(BIN_DIR)/echo-epoll-server

# ── Day 3 bench 客户端 ──
$(BIN_DIR)/echo-kp-bench: echo-kp-bench.c | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

# ── 从 Day 2 编译服务端 ──
$(BIN_DIR)/echo-epoll-lt-server: $(DAY02)/echo-epoll-lt-server.c | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/echo-epoll-server: $(DAY02)/echo-epoll-server.c | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# ═══════════════════════════════════════════════════════════
# 实验快捷命令
# ═══════════════════════════════════════════════════════════

# ── 启动服务端（终端 1） ──
run-lt: $(BIN_DIR)/echo-epoll-lt-server
	./bin/echo-epoll-lt-server

run-et: $(BIN_DIR)/echo-epoll-server
	./bin/echo-epoll-server

# ── 单次压测（终端 2） ──
# 短连接 100 并发 × 10 轮
bench-short: $(BIN_DIR)/echo-kp-bench
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode short

# 长连接 100 并发 × 10 轮
bench-long: $(BIN_DIR)/echo-kp-bench
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode long

# ── 连接数扫描 ──
# 100/500/1000/2000/5000 连接 × 10 轮，每轮都输出短+长对比
bench-scale: $(BIN_DIR)/echo-kp-bench
	@echo "========== 实验 3.2：连接数扫描 =========="
	@for c in 100 500 1000; do \
		echo ""; \
		echo "=== $$c 连接, 短连接 ==="; \
		./bin/echo-kp-bench 127.0.0.1 9988 $$c 10 --mode short 2>&1 | tail -12; \
		echo "=== $$c 连接, Keep-Alive ==="; \
		./bin/echo-kp-bench 127.0.0.1 9988 $$c 10 --mode long 2>&1 | tail -12; \
	done

# ── LT / ET 长连接对比 ──
bench-lt-short: $(BIN_DIR)/echo-kp-bench
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode short

bench-lt-long: $(BIN_DIR)/echo-kp-bench
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode long

# ET 启动在另一端口，先在 server 端指定 PORT
# 或者用环境变量（需 server 支持，此处为注释）
# bench-et-short:
# 	./bin/echo-kp-bench 127.0.0.1 9989 100 10 --mode short

# ── strace 对比 ──
# 验证短连接有 close() + connect()，长连接没有
strace-lt-short: $(BIN_DIR)/echo-kp-bench
	@echo "短连接模式下 echo-kp-bench 的 close/connect 调用数 (100 conn × 10 rounds):"
	@strace -c -e %net,close ./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode short 2>&1 | grep -E "close|connect|% time|total"
	@echo ""
	@echo "预期：close ≈ 1000 (= 100 conns × 10 rounds, 每轮关闭)"

strace-lt-long: $(BIN_DIR)/echo-kp-bench
	@echo "长连接模式下 echo-kp-bench 的 close/connect 调用数 (100 conn × 10 rounds):"
	@strace -c -e %net,close ./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode long 2>&1 | grep -E "close|connect|% time|total"
	@echo ""
	@echo "预期：close ≈ 100 (= 100 conns, 仅在连接结束时关闭)"

# ── 远程部署（使用时应设置 REMOTE_IP） ──
deploy:
	@if [ -z "$(REMOTE_IP)" ]; then \
		echo "请设置 REMOTE_IP 环境变量"; \
		echo "  make deploy REMOTE_IP=10.0.0.2 PORT=9988"; \
		exit 1; \
	fi
	ssh -o StrictHostKeyChecking=no root@$(REMOTE_IP) "mkdir -p /opt/echo"
	scp $(BIN_DIR)/echo-epoll-lt-server $(BIN_DIR)/echo-epoll-server \
	    root@$(REMOTE_IP):/opt/echo/

remote-bench: $(BIN_DIR)/echo-kp-bench
	@if [ -z "$(REMOTE_IP)" ]; then \
		echo "请设置 REMOTE_IP"; \
		echo "  make remote-bench REMOTE_IP=10.0.0.2"; \
		exit 1; \
	fi
	./bin/echo-kp-bench $(REMOTE_IP) 9988 100 10 --mode short
	@echo ""
	./bin/echo-kp-bench $(REMOTE_IP) 9988 100 10 --mode long

# ── 一键全跑（约 2-3 分钟） ──
#
# 注：服务端需提前单独启动：
#   终端1: make run-lt
#   终端2: 等待 server ready 后执行 make run-all
#
run-all:
	@echo "══════════════════════════════════════"
	@echo "  Day 3 实验自动采集"
	@echo "  $(shell date)"
	@echo "══════════════════════════════════════"
	@echo ""
	@echo ">>> 实验 3.1: Keep-Alive vs 短连接 QPS <<<"
	@echo ""
	@echo "=== LT 短连接 (3 轮) ==="
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode short | tail -13
	@echo ""
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode short | tail -13
	@echo ""
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode short | tail -13
	@echo ""
	@echo "=== LT Keep-Alive (3 轮) ==="
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode long | tail -13
	@echo ""
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode long | tail -13
	@echo ""
	./bin/echo-kp-bench 127.0.0.1 9988 100 10 --mode long | tail -13
	@echo ""
	@echo ">>> 实验 3.2: 连接数扫描 <<<"
	@for c in 100 500 1000 2000; do \
		echo ""; \
		echo "=== $$c conns, short ==="; \
		./bin/echo-kp-bench 127.0.0.1 9988 $$c 10 --mode short | tail -13; \
		echo "=== $$c conns, long ==="; \
		./bin/echo-kp-bench 127.0.0.1 9988 $$c 10 --mode long | tail -13; \
	done
	@echo ""
	@echo "══════════════════════════════════════"
	@echo "  实验采集完成"
	@echo "══════════════════════════════════════"

clean:
	rm -rf $(BIN_DIR)
