# Makefile —— 编译器重排 data-race demo(对应 tools/cache/compiler-reordering.md 第六节)
#
# 跨平台:Linux(g++) 与 macOS(clang++/c++) 均可。用法见本目录 README.md。
#
# 快速开始:
#   make            # 编译全部四个二进制(不运行)
#   make run        # 一键对比:先跑正确的原子版,再跑错误的普通版(带超时保护)
#   make asm        # 生成 -O0/-O2 反汇编,看编译器把自旋循环怎么动了
#   make clean

# ---- 编译器与平台探测 ----
CXX      ?= c++
UNAME_S  := $(shell uname -s)

# -O2 是关键:UB 只在优化下暴露;-pthread 两平台通用
CXXFLAGS := -O2 -std=c++17 -pthread -Wall

# 超时命令探测:Linux 有 timeout;macOS 需 `brew install coreutils` 得到 gtimeout。
# 都没有时,退化成"后台运行 + 到点 kill"的可移植方案(见 run-plain)。
TIMEOUT := $(shell command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null)

BINS := demo_atomic demo_plain spins_atomic spins_plain

# ---- 编译目标 ----
all: $(BINS)

demo_atomic: reorder_demo.cpp
	$(CXX) $(CXXFLAGS) -DUSE_ATOMIC $< -o $@

demo_plain: reorder_demo.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

spins_atomic: reorder_demo_spins.cpp
	$(CXX) $(CXXFLAGS) -DUSE_ATOMIC $< -o $@

spins_plain: reorder_demo_spins.cpp
	$(CXX) $(CXXFLAGS) $< -o $@

# ---- 运行:先看正确版,再看错误版 ----
run: run-atomic run-plain

run-atomic: demo_atomic
	@echo "=============================================================="
	@echo "[正确] 原子变量版(-DUSE_ATOMIC):顺序永远是 setting → saw"
	@echo "=============================================================="
	@./demo_atomic
	@echo ""

# 普通版可能死循环(表现A)或秒退顺序颠倒(表现B)——都是 data-race UB。
# 用超时保护:有 timeout/gtimeout 就限 3 秒;否则后台跑 3 秒再 kill。
run-plain: demo_plain
	@echo "=============================================================="
	@echo "[错误] 普通变量版:期待看到 UB —— 要么卡死(表现A),"
	@echo "        要么秒退且 'saw' 打在 'setting' 之前(表现B)"
	@echo "        (最多运行 3 秒,超时自动终止)"
	@echo "=============================================================="
ifneq ($(TIMEOUT),)
	@-$(TIMEOUT) 3 ./demo_plain; \
	  if [ $$? -eq 124 ]; then echo ">>> 3 秒超时被杀 = 表现A 死循环(等待线程永远看不到 flag)"; fi
else
	@./demo_plain & pid=$$!; \
	  sleep 3; \
	  if kill -0 $$pid 2>/dev/null; then \
	    echo ">>> 仍在运行,kill 之 = 表现A 死循环(等待线程永远看不到 flag)"; \
	    kill $$pid 2>/dev/null; \
	  fi; wait $$pid 2>/dev/null || true
endif
	@echo ""

# spins 变体:普通版稳定死循环(需 Ctrl-C 或超时);原子版正常退出
run-spins-atomic: spins_atomic
	@./spins_atomic

run-spins-plain: spins_plain
	@echo ">>> 普通版应稳定死循环(spins 疯涨不退出),最多 3 秒后终止"
ifneq ($(TIMEOUT),)
	@-$(TIMEOUT) 3 ./spins_plain || true
else
	@./spins_plain & pid=$$!; sleep 3; kill $$pid 2>/dev/null || true; wait $$pid 2>/dev/null || true
endif

# ---- 反汇编对比:坐实"编译器动了手脚" ----
# 生成 -O0 与 -O2 的汇编,diff 看自旋循环里 flag 的 load 有没有被提出/删除。
asm: reorder_demo.cpp
	$(CXX) -O0 -std=c++17 -pthread -S $< -o plain_O0.s
	$(CXX) -O2 -std=c++17 -pthread -S $< -o plain_O2.s
	$(CXX) -O2 -std=c++17 -pthread -DUSE_ATOMIC -S $< -o atomic_O2.s
	@echo "已生成 plain_O0.s / plain_O2.s / atomic_O2.s"
	@echo "看普通版 -O0 vs -O2 的自旋循环差异:  diff plain_O0.s plain_O2.s"
	@echo "  -O0: 循环体每轮都有一条 flag 的 load(x86: movzbl flag(%rip),... ; arm64: ldrb)"
	@echo "  -O2: 循环体里 flag 的 load 消失 —— 被提出循环(表现A)或整段删掉(表现B)"
	@echo "原子版 -O2 仍每轮真发 load:            grep -n 'flag' atomic_O2.s"

clean:
	rm -f $(BINS) *.s

.PHONY: all run run-atomic run-plain run-spins-atomic run-spins-plain asm clean
