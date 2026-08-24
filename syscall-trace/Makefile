# Makefile for syscall-trace demo
# 系统调用追踪实验 —— perf trace vs strace 对比

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g -lpthread -pthread
TARGET   := syscall_trace

.PHONY: all run clean help perf-trace perf-strace experiment bench run-experiments

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

# perf trace 汇总模式（推荐）
perf-trace: $(TARGET)
	@echo "=== perf trace -s (汇总) ==="
	perf trace -s ./$(TARGET) io 2>&1

# strace 对比（注意性能差异）
perf-trace-strace: $(TARGET)
	@echo "=== strace -c (对比) ==="
	time strace -c ./$(TARGET) io

# 只看特定 syscall
perf-trace-write: $(TARGET)
	@echo "=== perf trace -e write ==="
	perf trace -e write ./$(TARGET) io 2>&1

perf-trace-futex: $(TARGET)
	@echo "=== perf trace -e futex ==="
	perf trace -e futex ./$(TARGET) lock 2>&1

clean:
	rm -f $(TARGET)

# 一键跑完所有实验：编译 + 三模式 perf trace 汇总 + 特定 syscall + strace 对比
# 结果同时打印到屏幕并写入 experiment-<时间戳>.log，方便回填 README 第 3 章数据表
experiment bench run-experiments: $(TARGET)
	bash ./run_experiments.sh
