# Makefile —— TLB 页表翻译缓存抖动实验
#
# 常用目标:
#   make           编译 main.cpp → ./tlb_thrashing (默认 -O0 -g, 便于 perf 分析)
#   make run       编译并运行，打印 TLB 断崖表格
#   make release   以 -O2 编译 (验证优化不影响 TLB 结论)
#   make clean     删除生成物
#
# 运行要求: Linux x86-64 (依赖 4KB 页的 TLB 行为)，macOS 也能跑但 L2 STLB 容量不同。

CXX      ?= c++
CXXFLAGS ?= -O0 -g -Wall -Wextra -std=c++17

TARGET   := tlb_thrashing
SRC      := main.cpp

.PHONY: all run release clean

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

release: CXXFLAGS := -O2 -DNDEBUG -Wall -Wextra -std=c++17
release: clean $(TARGET)

clean:
	rm -f $(TARGET)
