# Makefile for cpu-model-sim-platform-lab
# Self-contained C++17 laboratory for articles E4/E5, F1-F5, G1-G3.
# No external library (gem5/QEMU/Spike concepts are modeled in readable code).

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
