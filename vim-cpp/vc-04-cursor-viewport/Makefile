CXX ?= c++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -O2

vc04: main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: vc04
	./vc04

clean:
	rm -f vc04

.PHONY: run clean
