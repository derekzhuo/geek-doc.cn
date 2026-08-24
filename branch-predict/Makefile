# Makefile for branch-predict demo
# 分支预测实验 —— 有序/随机/无分支三种写法对比

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g
TARGET   := branch_predict

# no-cmov 目标: 关闭 if-conversion，禁止编译器用 cmov 自动消除分支
TARGET_NOCMOV := branch_predict_no_cmov

.PHONY: all run clean help perf perf-annotate

all: $(TARGET) $(TARGET_NOCMOV)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

# 关闭 cmov 优化：让分支指令留在汇编里，方便观察真实分支预测行为
$(TARGET_NOCMOV): main.cpp
	$(CXX) $(CXXFLAGS) -fno-if-conversion -fno-if-conversion2 -o $@ $<

run: $(TARGET)
	./$(TARGET)

# 基础 perf stat 对比
perf: $(TARGET)
	@echo "=== -O2 默认 (cmov 可能自动消除分支) ==="
	perf stat -e cycles,instructions,branch-instructions,branch-misses \
		./$(TARGET) 2>&1 | grep -E '^\s|#'

perf-no-cmov: $(TARGET_NOCMOV)
	@echo "=== -O2 -fno-if-conversion (强制保留分支) ==="
	perf stat -e cycles,instructions,branch-instructions,branch-misses \
		./$(TARGET_NOCMOV) 2>&1 | grep -E '^\s|#'

# 汇编级定位: 哪个指令的分支预测失败最多
perf-annotate: $(TARGET_NOCMOV)
	perf record -e branch-misses:pp -g ./$(TARGET_NOCMOV)
	perf report --stdio

# 直接对比两版
perf-compare: perf perf-no-cmov

clean:
	rm -f $(TARGET) $(TARGET_NOCMOV) perf.data perf.data.old
