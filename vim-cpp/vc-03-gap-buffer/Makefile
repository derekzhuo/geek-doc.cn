CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall

bench: main.cpp
	$(CXX) $(CXXFLAGS) -o bench main.cpp

run: bench
	./bench

clean:
	rm -f bench
