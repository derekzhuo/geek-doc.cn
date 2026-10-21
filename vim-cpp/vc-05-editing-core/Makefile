CXX ?= clang++
CXXFLAGS ?= -O2 -std=c++17 -Wall

all: vc05

vc05: main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

# 非交互自检：6 个断言场景全过才输出 OK
check: vc05
	./vc05

clean:
	rm -f vc05

.PHONY: all check clean
