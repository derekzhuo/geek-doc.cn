CXX ?= clang++
CXXFLAGS := -std=c++17 -Wall -Wextra -pthread

.PHONY: all clean run

all: bin/bench-O2 bin/bench-O0

bin:
	mkdir -p bin

bin/bench-O2: src/main.cpp | bin
	$(CXX) -O2 $(CXXFLAGS) $< -o $@

bin/bench-O0: src/main.cpp | bin
	$(CXX) -O0 $(CXXFLAGS) $< -o $@

run: all
	bash run.sh

clean:
	rm -rf bin results.txt
