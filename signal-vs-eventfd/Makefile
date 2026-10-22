# Makefile for signal-vs-eventfd demo
# 信号通知 vs eventfd 通知性能对比 —— pthread_kill/sigwait vs eventfd write/read

CC       := gcc
CFLAGS   := -O2 -std=c11 -Wall -Wextra -pthread
TARGET   := signal_vs_eventfd

.PHONY: all run clean

all: $(TARGET)

$(TARGET): main.c
	$(CC) $(CFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET)
