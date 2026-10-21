CXX ?= c++
CXXFLAGS ?= -std=c++17 -O2 -Wall -Wextra

all: vc01-raw selftest

vc01-raw: main.cpp term.hpp
	$(CXX) $(CXXFLAGS) -o $@ main.cpp

selftest: selftest.cpp term.hpp
	$(CXX) $(CXXFLAGS) -o $@ selftest.cpp

check: selftest
	./selftest

run: vc01-raw
	./vc01-raw

clean:
	rm -f vc01-raw selftest

.PHONY: all check run clean
