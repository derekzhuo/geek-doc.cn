# 去虚化条件基准：none（-O2）/ lto（-O2 -flto）/ pgo（LTO + 剖面引导）。
# run.sh 负责编排「插桩 → 训练 → merge → 剖面引导重建」并采集反汇编证据。
CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall
SRCS := main.cpp factory.cpp

.PHONY: all clean
all: bin/bench-none bin/bench-lto bin/bench-pgo

bin:
	mkdir -p bin

bin/bench-none: $(SRCS) types.hpp factory.hpp | bin
	$(CXX) $(CXXFLAGS) $(SRCS) -o $@

bin/bench-lto: $(SRCS) types.hpp factory.hpp | bin
	$(CXX) $(CXXFLAGS) -flto $(SRCS) -o $@

bin/bench-instrumented: $(SRCS) types.hpp factory.hpp | bin
	$(CXX) $(CXXFLAGS) -flto -fprofile-generate=. $(SRCS) -o $@

# 依赖 run.sh 先产出 pgo.profdata；单独 make 本目标前需保证剖面文件存在。
bin/bench-pgo: $(SRCS) types.hpp factory.hpp pgo.profdata | bin
	$(CXX) $(CXXFLAGS) -flto -fprofile-use=pgo.profdata $(SRCS) -o $@

clean:
	rm -rf bin *.profraw *.profdata
