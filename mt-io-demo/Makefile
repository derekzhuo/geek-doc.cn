# Makefile for mt-io-demo
# 多线程 + IO 混合程序演示 —— 配合 perf-multithread-io-analysis.md 三步法

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g -pthread
TARGET   := mt_io_demo

.PHONY: all run clean help

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

# 默认跑一个"混合场景"：CPU + IO + 锁，正好贴合文档主题
run: $(TARGET)
	./$(TARGET) --cpu 4 --io 2 --lock 2 --duration 20

# 制造"模式 A：CPU 满载但 IPC 极低"（低 IPC + cache-miss）
run-mode-a: $(TARGET)
	./$(TARGET) --cpu 2 --cpu-mode mem --io 0 --lock 0 --duration 20

# 制造"模式 B：锁竞争"（高 voluntary 切换）
run-mode-b: $(TARGET)
	./$(TARGET) --cpu 0 --io 0 --lock 8 --duration 20

# 制造"模式 C：IO 型线程狂调 syscall"
run-mode-c: $(TARGET)
	./$(TARGET) --cpu 0 --io 8 --io-us 200 --lock 0 --duration 20

clean:
	rm -f $(TARGET) perf.data perf.data.old

help:
	@echo "make           编译"
	@echo "make run       混合场景 (默认)"
	@echo "make run-mode-a 模式A: 低IPC计算"
	@echo "make run-mode-b 模式B: 锁竞争"
	@echo "make run-mode-c 模式C: IO syscall 风暴"
