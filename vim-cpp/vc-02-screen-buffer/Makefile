CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall

all: vc02

vc02: main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

# 实测：输出丢 /dev/null，排除终端 IO 干扰
bench: vc02
	./vc02 single 3000 > /dev/null
	./vc02 double 3000 > /dev/null

clean:
	rm -f vc02

.PHONY: all bench clean
