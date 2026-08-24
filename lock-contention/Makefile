# Makefile for lock-contention demo
# 锁争用分析实验 —— perf lock record/report

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g -lpthread -pthread
TARGET   := lock_contention

.PHONY: all run clean help perf-lock

all: $(TARGET)

$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET) 10

# 录制锁事件（需 root + CONFIG_LOCKDEP）
perf-lock: $(TARGET)
	@echo "=== 录制锁事件并分析 ==="
	sudo perf lock record -a ./$(TARGET) 10
	perf lock report

# 带调用栈的锁分析
perf-lock-stack: $(TARGET)
	@echo "=== 录制锁事件 + 调用栈 ==="
	sudo perf lock record -g -a ./$(TARGET) 10
	perf lock report -k

# syscall 视角：数 futex 调用量
perf-futex: $(TARGET)
	@echo "=== 统计 futex 系统调用 ==="
	perf stat -e 'syscalls:sys_enter_futex' -a sleep 10 2>&1

clean:
	rm -f $(TARGET) perf.data perf.data.old
