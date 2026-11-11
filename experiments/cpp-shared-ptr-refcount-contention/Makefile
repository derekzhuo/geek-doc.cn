# shared_ptr 原子引用计数争用基准，线程数扫档 1/2/4/6/8/12。
CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall

.PHONY: all clean
all: bin/bench

bin:
	mkdir -p bin

bin/bench: main.cpp payload.hpp | bin
	$(CXX) $(CXXFLAGS) main.cpp -o $@

clean:
	rm -rf bin
