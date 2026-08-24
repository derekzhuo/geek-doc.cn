# Makefile for stall-analysis demo
# CPU 流水线停顿模式实验 —— 前端/后端停顿根因定位

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g
TARGET   := stall_analysis

.PHONY: all run clean help perf-all perf1 perf2 perf3 perf4

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

# 单模式跑（供 perf 用）
perf1: $(TARGET)
	@echo "=== 模式1: 纯计算（对照组）==="
	perf stat -e cycles,instructions,stalled-cycles-frontend,stalled-cycles-backend,L1-icache-load-misses,branch-misses,cache-references,cache-misses ./$(TARGET) 1

perf2: $(TARGET)
	@echo "=== 模式2: 函数指针间接调用（前端停顿）==="
	perf stat -e cycles,instructions,stalled-cycles-frontend,stalled-cycles-backend,L1-icache-load-misses,branch-misses,cache-references,cache-misses ./$(TARGET) 2

perf3: $(TARGET)
	@echo "=== 模式3: 随机内存访问（后端停顿 - cache miss）==="
	perf stat -e cycles,instructions,stalled-cycles-frontend,stalled-cycles-backend,L1-icache-load-misses,branch-misses,cache-references,cache-misses,LLC-loads,LLC-load-misses ./$(TARGET) 3

perf4: $(TARGET)
	@echo "=== 模式4: 长依赖链（后端停顿 - 数据依赖）==="
	perf stat -e cycles,instructions,stalled-cycles-frontend,stalled-cycles-backend,L1-icache-load-misses,branch-misses,cache-references,cache-misses ./$(TARGET) 4

perf-all: perf1 perf2 perf3 perf4

clean:
	rm -f $(TARGET)
