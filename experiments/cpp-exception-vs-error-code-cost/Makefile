# 异常/错误码/Expected 三机制基准，正常路径与错误路径分别计时。
CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall
SRCS := main.cpp logic.cpp

.PHONY: all clean
all: bin/bench

bin:
	mkdir -p bin

bin/bench: $(SRCS) logic.hpp | bin
	$(CXX) $(CXXFLAGS) $(SRCS) -o $@

clean:
	rm -rf bin
