# Makefile for cache-miss demo
# 缓存未命中模式实验 —— 顺序/随机/跨步遍历对比

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g
TARGET   := cache_miss

.PHONY: all run clean help

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

# 跑全部模式对比表
run: $(TARGET)
	./$(TARGET)

# 逐个模式单独跑 + perf stat 测量（展示缓存事件差异）
perf-seq: $(TARGET)
	@echo "=== 顺序访问 ==="
	perf stat -e cycles,instructions,cache-references,cache-misses \
		./$(TARGET) seq 2>&1 | grep -E '^\s|#'

perf-rand: $(TARGET)
	@echo "=== 随机访问 ==="
	perf stat -e cycles,instructions,cache-references,cache-misses \
		./$(TARGET) rand 2>&1 | grep -E '^\s|#'

perf-stride64: $(TARGET)
	@echo "=== stride=64 (一个cache line) ==="
	perf stat -e cycles,instructions,cache-references,cache-misses \
		./$(TARGET) stride 64 2>&1 | grep -E '^\s|#'

perf-stride256: $(TARGET)
	@echo "=== stride=256 (多cache line) ==="
	perf stat -e cycles,instructions,cache-references,cache-misses \
		./$(TARGET) stride 256 2>&1 | grep -E '^\s|#'

# L1 缓存细节
perf-l1-seq: $(TARGET)
	@echo "=== L1 cache: 顺序 ==="
	perf stat -e L1-dcache-loads,L1-dcache-load-misses \
		./$(TARGET) seq 2>&1 | grep -E '^\s|#'

perf-l1-rand: $(TARGET)
	@echo "=== L1 cache: 随机 ==="
	perf stat -e L1-dcache-loads,L1-dcache-load-misses \
		./$(TARGET) rand 2>&1 | grep -E '^\s|#'

# LLC 缓存细节
perf-llc-seq: $(TARGET)
	@echo "=== LLC: 顺序 ==="
	perf stat -e LLC-loads,LLC-load-misses ./$(TARGET) seq 2>&1 | grep -E '^\s|#'

perf-llc-rand: $(TARGET)
	@echo "=== LLC: 随机 ==="
	perf stat -e LLC-loads,LLC-load-misses ./$(TARGET) rand 2>&1 | grep -E '^\s|#'

# 一键对比: 顺序 vs 随机 vs stride=64 vs stride=256
perf-all: perf-seq perf-rand perf-stride64 perf-stride256

clean:
	rm -f $(TARGET)
