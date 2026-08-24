# Makefile for indirect-branch demo
# 间接分支预测实验 —— 虚函数 / 函数指针 / switch 跳转表

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g
TARGET   := indirect_branch

.PHONY: all run perf perf-branch-loads perf-mono perf-mega perf-dual perf-switch-seq perf-switch-rnd clean

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

# 基础 perf stat：同时看直接分支和间接分支
# 注意：全模式混在一起指标没意义 —— 用 --mode 隔离后再跑
perf: $(TARGET)
	@echo "=== 直接分支 (jcc) + 间接分支 (jmp *%rax / call *%rax) ==="
	@echo "提示：用 ./$(TARGET) --mode <模式> 单跑一种模式看真实数据"
	perf stat -e cycles,instructions,\
branch-instructions,branch-misses,\
branch-loads,branch-load-misses \
		./$(TARGET)

# 只看间接分支预测（同样建议 --mode 隔离）
perf-branch-loads: $(TARGET)
	@echo "=== 间接分支预测 (branch-loads / branch-load-misses) ==="
	@echo "提示：用 ./$(TARGET) --mode <模式> 单跑一种模式看真实数据"
	perf stat -e branch-loads,branch-load-misses ./$(TARGET)

# 按模式单独跑 perf stat —— 这是正确的对比方式
perf-mono: $(TARGET)
	@echo "=== 单态虚函数 (monomorphic) ==="
	perf stat -e branch-loads,branch-load-misses ./$(TARGET) --mode mono

perf-mega: $(TARGET)
	@echo "=== 巨态虚函数 (megamorphic) ==="
	perf stat -e branch-loads,branch-load-misses ./$(TARGET) --mode mega

perf-dual: $(TARGET)
	@echo "=== 双态虚函数 (bimorphic) ==="
	perf stat -e branch-loads,branch-load-misses ./$(TARGET) --mode dual

perf-switch-seq: $(TARGET)
	@echo "=== switch 顺序 op ==="
	perf stat -e branch-loads,branch-load-misses ./$(TARGET) --mode switch-seq

perf-switch-rnd: $(TARGET)
	@echo "=== switch 随机 op ==="
	perf stat -e branch-loads,branch-load-misses ./$(TARGET) --mode switch-rnd

# 定位具体函数 —— 用 --mode 隔离，否则各种模式混在一起指标没意义
perf-record: perf-record-mono perf-record-mega

perf-record-mono: $(TARGET)
	@echo "=== perf record: 单态虚函数 (monomorphic) ==="
	perf record -e branch-load-misses:pp -g -o perf.data.mono ./$(TARGET) --mode mono
	@echo "--- 进入热点函数后: perf annotate -i perf.data.mono ---"

perf-record-mega: $(TARGET)
	@echo "=== perf record: 巨态虚函数 (megamorphic) ==="
	perf record -e branch-load-misses:pp -g -o perf.data.mega ./$(TARGET) --mode mega
	@echo "--- 进入热点函数后: perf annotate -i perf.data.mega ---"

perf-record-dual: $(TARGET)
	perf record -e branch-load-misses:pp -g -o perf.data.dual ./$(TARGET) --mode dual

perf-record-switch-seq: $(TARGET)
	perf record -e branch-load-misses:pp -g -o perf.data.swseq ./$(TARGET) --mode switch-seq

perf-record-switch-rnd: $(TARGET)
	perf record -e branch-load-misses:pp -g -o perf.data.swrnd ./$(TARGET) --mode switch-rnd

clean:
	rm -f $(TARGET) perf.data perf.data.old perf.data.mono perf.data.mega perf.data.dual perf.data.swseq perf.data.swrnd
