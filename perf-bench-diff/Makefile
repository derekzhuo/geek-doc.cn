# Makefile for perf-bench-diff demo
# 微基准测试 + 优化前后 perf diff 对比

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g
TARGET   := perf_bench_diff

.PHONY: all run clean help perf-diff perf-bench

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

# 优化前后对比
perf-diff: $(TARGET)
	@echo "=== 录制基线版 ==="
	perf record -o perf_base.data ./$(TARGET) base
	@echo "\n=== 录制优化版 ==="
	perf record -o perf_opt.data ./$(TARGET) opt
	@echo "\n=== perf diff ==="
	perf diff perf_base.data perf_opt.data

# 系统微基准
perf-bench:
	@echo "=== memcpy 带宽 ==="
	perf bench mem memcpy
	@echo "\n=== 调度: pipe ==="
	perf bench sched pipe
	@echo "\n=== 调度: messaging ==="
	perf bench sched messaging

clean:
	rm -f $(TARGET) perf_base.data perf_opt.data perf.data
