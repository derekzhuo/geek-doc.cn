CXX ?= clang++
CXXFLAGS := -std=c++17 -Wall -Wextra
SRCS := $(wildcard src/g*.cpp) src/main.cpp
GROUPS := $(patsubst src/%.cpp,%,$(wildcard src/g*.cpp))

# 向量化报告三兄弟：成功 / 未命中 / 分析（含未向量化原因）
RFLAGS := -Rpass=loop-vectorize -Rpass-missed=loop-vectorize \
          -Rpass-analysis=loop-vectorize

.PHONY: all clean run reports

all: bin/bench-O2 bin/bench-scalar bin/bench-native

bin:
	mkdir -p $@

bin/bench-O2: $(SRCS) src/loops.hpp | bin
	$(CXX) -O2 $(CXXFLAGS) $(SRCS) -o $@

# 关掉向量化与 SLP，作为标量对照，用来算加速比
bin/bench-scalar: $(SRCS) src/loops.hpp | bin
	$(CXX) -O2 -fno-vectorize -fno-slp-vectorize $(CXXFLAGS) $(SRCS) -o $@

# 放开到本机 ISA（i7-9750H 含 AVX2），看向量宽度从 2 提到 4
bin/bench-native: $(SRCS) src/loops.hpp | bin
	$(CXX) -O2 -march=native $(CXXFLAGS) $(SRCS) -o $@

# 逐组采集编译器向量化报告：普通 -O2 / 标量档 / native 档
reports:
	@mkdir -p reports
	@for g in $(GROUPS); do \
	  $(CXX) -O2 $(CXXFLAGS) $(RFLAGS) -c src/$$g.cpp -o /dev/null \
	    2> reports/O2-$$g.txt || true; \
	  $(CXX) -O2 -fno-vectorize $(CXXFLAGS) $(RFLAGS) -c src/$$g.cpp -o /dev/null \
	    2> reports/scalar-$$g.txt || true; \
	  $(CXX) -O2 -march=native $(CXXFLAGS) $(RFLAGS) -c src/$$g.cpp -o /dev/null \
	    2> reports/native-$$g.txt || true; \
	done
	@# 另采一份 -funroll-loops 全局展开档，对照 pragma unroll
	$(CXX) -O2 -funroll-loops $(CXXFLAGS) $(RFLAGS) -c src/g9_unroll.cpp -o /dev/null \
	  2> reports/funroll-g9_unroll.txt || true

run: all reports
	bash run.sh

clean:
	rm -rf bin reports results.txt
