# Makefile —— 编译性能分析练习程序 cpu_demo
#
# 常用目标：
#   make            编译 main.cpp，生成 ./cpu_demo（带 -g、-O0，便于 perf 分析）
#   make run        编译并运行 cpu_demo（交互选择场景）
#   make release    以 -O2 编译（观察编译器优化对 CPU 消耗的影响）
#   make clean      删除生成物
#
# 说明：main.cpp 依赖 /proc，只能在 Linux 上运行（macOS 可编译不可运行）。

CXX      ?= c++
# 默认 -O0 -g：保留所有函数与行号，perf 火焰图才看得到有意义的调用栈
CXXFLAGS ?= -O0 -g -Wall -Wextra -std=c++17 -pthread

TARGET   := cpu_demo
SRC      := main.cpp

.PHONY: all run release clean

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

# 用 -O2 重新编译，对比优化后用户态热循环是否被消除
release: CXXFLAGS := -O2 -g -Wall -Wextra -std=c++17 -pthread
release: clean $(TARGET)

clean:
	rm -f $(TARGET)
