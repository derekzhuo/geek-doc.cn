# Makefile for perf-probe demo
# 动态探针插桩实验 —— perf probe (uprobe) / USDT 静态点 / ftrace 对照
#
# 主目标 perf_probe_demo 跨平台编译（Linux/macOS）。
# usdt_demo 仅 Linux 构建（依赖系统 <sys/sdt.h>），macOS 上跳过。
# cpp_members_demo / cpp_members_hidden 为 C++ 成员函数 uprobe 实验
# （默认 -O0 -g 保留符号与行号，教学基准；hidden 变体对照符号可见性）。

CXX      := g++
CXXFLAGS := -O2 -std=c++17 -Wall -g
TARGET   := perf_probe_demo

UNAME_S  := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  USDT_TARGET := usdt_demo
else
  USDT_TARGET :=
endif

# C++ 成员函数实验：默认可见性 + hidden 可见性两个变体
CPP_MEMBERS     := cpp_members_demo
CPP_MEMBERS_HID := cpp_members_hidden
CPP_MEMBERS_FLAGS := -O0 -g -std=c++17 -Wall -fno-omit-frame-pointer

.PHONY: all run clean help usdt cpp-members cpp-members-hidden

all: $(TARGET) $(USDT_TARGET)

# 主目标：uprobe 动态插桩实验程序
$(TARGET): main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

# USDT 对照程序（仅 Linux）：用系统 <sys/sdt.h> 预埋静态探针
usdt: $(USDT_TARGET)
ifeq ($(UNAME_S),Linux)
$(USDT_TARGET): usdt_demo.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<
else
$(USDT_TARGET):
	@echo "usdt_demo 仅 Linux 构建（依赖 <sys/sdt.h>），当前 $(UNAME_S) 跳过"
endif

# C++ 成员函数 uprobe 实验（默认可见性）
cpp-members: $(CPP_MEMBERS)
$(CPP_MEMBERS): cpp-members.cpp
	$(CXX) $(CPP_MEMBERS_FLAGS) -o $@ $<

# C++ 成员函数 uprobe 实验（-fvisibility=hidden 变体，对照符号可见性）
cpp-members-hidden: $(CPP_MEMBERS_HID)
$(CPP_MEMBERS_HID): cpp-members.cpp
	$(CXX) $(CPP_MEMBERS_FLAGS) -fvisibility=hidden -o $@ $<

run: $(TARGET)
	./$(TARGET) 30

clean:
	rm -f $(TARGET) $(USDT_TARGET) $(CPP_MEMBERS) $(CPP_MEMBERS_HID)
