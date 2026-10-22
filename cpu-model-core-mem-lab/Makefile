# Makefile for cpu-model-core-mem-lab
# Self-contained C++17 laboratory for articles A3/A4/A5, B1-B5, E2/E3.
# No external library, no SystemC required.

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
	rm -f $(TARGET)
