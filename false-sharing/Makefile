# Makefile for false-sharing demo
# 伪共享检测实验 —— perf c2c record/report

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g -lpthread -pthread
TARGET   := false_sharing

.PHONY: all run clean help perf-c2c

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET) 10

# 录制 c2c 事件（需 root + PEBS）
perf-c2c: $(TARGET)
	@echo "=== 录制 c2c 事件 ==="
	sudo perf c2c record -a ./$(TARGET) 10
	@echo "\n=== c2c 报告 ==="
	perf c2c report

# 详细地址级报告
perf-c2c-detail: $(TARGET)
	sudo perf c2c record -a ./$(TARGET) 10
	perf c2c report -d

clean:
	rm -f $(TARGET) perf.data perf.data.old
