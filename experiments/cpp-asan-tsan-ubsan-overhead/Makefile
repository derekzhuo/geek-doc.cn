# Sanitizer 运行时开销基准：同一 bench.cpp 出五种插桩构建，另含 TSan/UBSan 检测能力演示。
# 注意：ASan 与 TSan 运行时互斥，不能在同一次链接中同时启用（clang 直接报错）。
CXX ?= clang++
COMMON := -O2 -g -std=c++17 -Wall

.PHONY: all clean
all: bin/bench-plain bin/bench-ubsan bin/bench-asan bin/bench-aubsan bin/bench-tsan \
     bin/race bin/race-fixed bin/ub-demo

bin:
	mkdir -p bin

bin/bench-plain: bench.cpp | bin
	$(CXX) $(COMMON) bench.cpp -o $@

bin/bench-asan: bench.cpp | bin
	$(CXX) $(COMMON) -fsanitize=address bench.cpp -o $@

bin/bench-ubsan: bench.cpp | bin
	$(CXX) $(COMMON) -fsanitize=undefined bench.cpp -o $@

bin/bench-aubsan: bench.cpp | bin
	$(CXX) $(COMMON) -fsanitize=address,undefined bench.cpp -o $@

bin/bench-tsan: bench.cpp | bin
	$(CXX) $(COMMON) -fsanitize=thread bench.cpp -o $@

bin/race: race_demo.cpp | bin
	$(CXX) -O1 -g -std=c++17 -Wall -fsanitize=thread race_demo.cpp -o $@

bin/race-fixed: race_demo.cpp | bin
	$(CXX) -O1 -g -std=c++17 -Wall -DRACE_FIXED -fsanitize=thread race_demo.cpp -o $@

bin/ub-demo: ub_demo.cpp | bin
	$(CXX) -O1 -g -std=c++17 -Wall -fsanitize=undefined ub_demo.cpp -o $@

clean:
	rm -rf bin
