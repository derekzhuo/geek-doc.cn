# Makefile —— crash 信号 demo 集(对应 ../../tools/crash/signals.md 第二节)
#
# 跨平台: Linux(gcc/g++) 与 macOS(clang/c++) 均可编译运行。
#   make        # 编译全部 demo(不运行)
#   make run    # 逐个运行,带超时保护,打印退出码并翻译成信号名
#   make clean  # 删除所有二进制
#
# 重要提示: 堆检测类 demo(double free / heap overflow)在 Linux/glibc 上现象最标准
# (稳定 SIGABRT + 明确文案);macOS 用 libmalloc,可能是不同文案、不同信号甚至不崩。
# 详见本目录 README.md。

# ---- 编译器与平台探测 ----
CC       ?= cc
CXX      ?= c++
UNAME_S  := $(shell uname -s)

# -O0: 关闭优化,防止编译器把 UB/无副作用代码优化掉,让现象最稳定
# -g : 带符号,方便配合 GDB / core dump 复盘
CFLAGS   := -O0 -g -Wall -Wno-unused-variable
CXXFLAGS := -O0 -g -Wall -std=c++17

# 超时命令探测: Linux 有 timeout;macOS 需 `brew install coreutils` 得到 gtimeout。
# 都没有时退化成"后台运行 + 到点 kill"的可移植方案(见 run 目标)。
TIMEOUT  := $(shell command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null)

# 每个 demo 的超时秒数(栈溢出/递归可能跑一会儿,给足)
TMO      := 10

# C 语言 demo
C_BINS   := segv_null segv_wild segv_readonly segv_stackoverflow \
            abrt_double_free abrt_heap_overflow abrt_assert \
            fpe_divzero ill_badfnptr
# C++ demo
CXX_BINS := abrt_uncaught

BINS     := $(C_BINS) $(CXX_BINS)

# ---- 编译 ----
all: $(BINS)
	@echo ""
	@echo ">>> 编译完成($(UNAME_S) / CC=$(CC) CXX=$(CXX))。运行: make run"

# C 文件: 同名 .c -> 可执行
$(C_BINS): %: %.c
	$(CC) $(CFLAGS) $< -o $@

# C++ 文件
abrt_uncaught: abrt_uncaught.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

# ---- 运行: 逐个跑,打印退出码 + 信号名 ----
# 退出码约定: 进程被信号 N 杀死时,shell 的 $? = 128 + N。
# run-one 封装: 带超时跑一个 demo,捕获退出码,翻译成信号名。
run: all
	@echo "=============================================================="
	@echo " crash 信号 demo 逐个运行(平台: $(UNAME_S))"
	@echo " 退出码约定: 被信号 N 杀死 => 退出码 = 128 + N"
	@echo "=============================================================="
	@for b in $(BINS); do \
	  $(MAKE) -s run-one BIN=$$b; \
	done
	@echo "=============================================================="
	@echo " 全部跑完。128+signum 对照见 README.md;各 demo 原理见文件头注释。"
	@echo "=============================================================="

# 单个 demo 的运行 + 结果翻译
run-one:
	@printf -- "---- %-22s " "$(BIN)"
ifneq ($(TIMEOUT),)
	@$(TIMEOUT) $(TMO) ./$(BIN) >/dev/null 2>&1; code=$$?; $(MAKE) -s explain CODE=$$code
else
	@( ./$(BIN) >/dev/null 2>&1 & pid=$$!; \
	   ( sleep $(TMO); kill -9 $$pid 2>/dev/null ) & watcher=$$!; \
	   disown $$watcher 2>/dev/null || true; \
	   wait $$pid 2>/dev/null; code=$$?; \
	   kill $$watcher 2>/dev/null; \
	   $(MAKE) -s explain CODE=$$code ) 2>/dev/null
endif

# 把退出码翻译成人话: 128+signum => 信号名
explain:
	@code=$(CODE); \
	if [ $$code -eq 124 ]; then \
	  echo "[超时未崩] timeout 到点被杀(退出码 124),该 demo 在本平台未在 $(TMO)s 内崩溃"; \
	elif [ $$code -gt 128 ]; then \
	  sig=$$((code - 128)); \
	  name=$$(kill -l $$sig 2>/dev/null); \
	  echo "退出码 $$code => 被信号 $$sig (SIG$$name) 杀死"; \
	elif [ $$code -eq 137 ]; then \
	  echo "退出码 137 => SIGKILL(可能是超时兜底 kill -9)"; \
	elif [ $$code -eq 0 ]; then \
	  echo "退出码 0 => 未崩溃(正常退出?本平台该 UB 未触发)"; \
	else \
	  echo "退出码 $$code => 正常退出/自定义退出码(未被信号杀死)"; \
	fi

clean:
	rm -f $(BINS)
	rm -rf *.dSYM

.PHONY: all run run-one explain clean
