# RVO/NRVO/移动语义基准：默认构建与 -fno-elide-constructors 反证构建。
CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall
SRCS := main.cpp widgets.cpp

.PHONY: all clean
all: bin/bench bin/bench-no-elide

bin:
	mkdir -p bin

bin/bench: $(SRCS) widgets.hpp | bin
	$(CXX) $(CXXFLAGS) $(SRCS) -o $@

bin/bench-no-elide: $(SRCS) widgets.hpp | bin
	$(CXX) $(CXXFLAGS) -fno-elide-constructors $(SRCS) -o $@

clean:
	rm -rf bin
