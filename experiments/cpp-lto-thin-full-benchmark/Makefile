# 三档 LTO 对照构建：none（-O2 无 LTO）/ full（-flto 全量）/ thin（-flto=thin）。
# 构建耗时与二进制体积由 run.sh 外部测量，Makefile 只负责可复现的编译动作。
CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall
NWORKERS ?= 8

WORKER_SRCS := $(addsuffix .cpp,$(addprefix worker,$(shell seq 0 $$(($(NWORKERS)-1)))))
SRCS := main.cpp sumparts.cpp $(WORKER_SRCS)

.PHONY: all gen clean
all: bin/lto-none bin/lto-full bin/lto-thin

gen:
	bash gen_workers.sh $(NWORKERS)

bin:
	mkdir -p bin

bin/lto-none: gen $(SRCS) work.hpp | bin
	$(CXX) $(CXXFLAGS) $(SRCS) -o $@

bin/lto-full: gen $(SRCS) work.hpp | bin
	$(CXX) $(CXXFLAGS) -flto $(SRCS) -o $@

bin/lto-thin: gen $(SRCS) work.hpp | bin
	$(CXX) $(CXXFLAGS) -flto=thin $(SRCS) -o $@

clean:
	rm -rf bin worker*.cpp
