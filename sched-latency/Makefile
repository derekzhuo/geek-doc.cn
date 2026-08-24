# Makefile for sched-latency demo
# 调度延迟诊断实验 —— perf sched record/latency/timehist/map

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g -lpthread -pthread
TARGET   := sched_latency

.PHONY: all run clean help perf-sched

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

# 录制调度事件并生成完整分析（需 root）
perf-sched: $(TARGET)
	@echo "=== 录制调度事件 ==="
	sudo perf sched record -a ./$(TARGET) all 10
	@echo "\n=== 调度延迟 ==="
	perf sched latency
	@echo "\n=== 时间线汇总 ==="
	perf sched timehist -s

# 时间线可视化
perf-sched-viz: $(TARGET)
	sudo perf sched record -a ./$(TARGET) all 10
	perf sched timehist -V

# ASCII 调度图
perf-sched-map: $(TARGET)
	sudo perf sched record -a ./$(TARGET) all 10
	perf sched map

clean:
	rm -f $(TARGET) perf.data perf.data.old
