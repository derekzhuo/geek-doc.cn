CXX ?= c++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -O2

main: main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: main
	./main

clean:
	rm -f main

.PHONY: run clean
