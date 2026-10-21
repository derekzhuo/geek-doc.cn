CXX ?= g++
CXXFLAGS ?= -O2 -Wall

all: bench_0 bench_1 bench_2 bench_3

bench_%: editor_bench.cpp
	$(CXX) $(CXXFLAGS) -DOPT=$* -o $@ $<

bench: all
	@for n in 0 1 2 3; do ./bench_$$n 300; done

clean:
	rm -f bench_0 bench_1 bench_2 bench_3

.PHONY: all bench clean
