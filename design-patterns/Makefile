# Makefile for design-patterns demos
# 23 个 GoF 设计模式的可运行 C++ 示例（C++17）
# 每个 .cpp 独立编译为同名可执行文件；模式介绍见
# architecture/design-patterns/ 下各模式独立文档。

CXX      := g++
CXXFLAGS := -O0 -g -std=c++17 -Wall -Wextra

SRCS := $(wildcard *.cpp)
BINS := $(SRCS:.cpp=)

.PHONY: all run single clean

all: $(BINS)

# 通配规则：singleton.cpp -> singleton
$(BINS): %: %.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

# make run            —— 依次运行全部示例
# make run PATTERN=s  —— 运行名字含 "s" 的示例（如 singleton / state / strategy）
run: all
	@if [ -n "$(PATTERN)" ]; then \
		for b in $(BINS); do case "$$b" in *$(PATTERN)*) echo "=== $$b ==="; ./$$b;; esac; done; \
	else \
		for b in $(BINS); do echo "=== $$b ==="; ./$$b; done; \
	fi

clean:
	rm -f $(BINS)
