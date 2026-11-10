# PGO 两阶段基准：baseline（-O2）/ instrumented（-fprofile-generate）/ pgo（-fprofile-use）。
# run.sh 负责编排「插桩 → 训练 → merge → 剖面引导重建」完整流程。
CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall
SRCS := main.cpp classifier.cpp

.PHONY: all clean
all: bin/baseline bin/instrumented bin/pgo

bin:
	mkdir -p bin

bin/baseline: $(SRCS) classifier.hpp | bin
	$(CXX) $(CXXFLAGS) $(SRCS) -o $@

bin/instrumented: $(SRCS) classifier.hpp | bin
	$(CXX) $(CXXFLAGS) -fprofile-generate=. $(SRCS) -o $@

# 依赖 run.sh 先产出 pgo.profdata；单独 make 本目标前需保证剖面文件存在。
bin/pgo: $(SRCS) classifier.hpp pgo.profdata | bin
	$(CXX) $(CXXFLAGS) -fprofile-use=pgo.profdata $(SRCS) -o $@

clean:
	rm -rf bin *.profraw *.profdata
