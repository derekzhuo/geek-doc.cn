# Makefile for cpu-model-isa-iss demo
# RV32I 子集解释器 ISS + 统计式 CPI 模型（功能/性能分离）实验

CXX      ?= g++
CXXFLAGS ?= -O2 -std=c++17 -Wall -Wextra -g
TARGET   := iss

.PHONY: all run clean

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET)
