CXX ?= g++
CXXFLAGS := -O2 -std=c++17 -Wall -Wextra -pthread

.PHONY: all clean run

all: bin/lock_bench

bin:
	mkdir -p bin

bin/lock_bench: src/main.cpp | bin
	$(CXX) $(CXXFLAGS) $< -o $@

run: all
	bash run.sh

clean:
	rm -rf bin results.txt
