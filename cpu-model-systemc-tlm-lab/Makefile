# Makefile for cpu-model-systemc-tlm-lab
# Self-contained C++17 laboratory for articles C1-C5 and D1-D5.
# No SystemC / external library: it models the same scheduling and TLM
# transport semantics in readable plain C++17.

CXX      ?= g++
CXXFLAGS ?= -O2 -std=c++17 -Wall -Wextra -g
TARGET   := lab

.PHONY: all run clean

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET) all

clean:
	rm -f $(TARGET) mini_trace.vcd
