# 仿真工程通用 Makefile —— iverilog / verilator 双后端
# 用法：make                  默认 iverilog 编译 + vvp 跑仿真
#       make SIM=verilator    换 Verilator --binary 后端
#       make lint             verilator -Wall 静态检查
#       make wave             gtkwave 看波形
#       make clean

# ---- 可配置变量（命令行可覆盖；注意行尾不要带空格再接注释）----
SIM     ?= iverilog
TOP     := tb_counter
SRCS    := counter.v tb_counter.v
BUILD   := build
WIDTH   ?= 8
SEED    ?= 1

# ---- 后端工具 ----
IVERILOG  := iverilog
VVP       := vvp
VERILATOR := verilator

.PHONY: all sim lint wave clean regress
all: sim

ifeq ($(SIM),iverilog)
# ---- Icarus Verilog 后端：先编译成 vvp 映像再执行 ----
sim: $(BUILD)/sim.vvp
	$(VVP) -l $(BUILD)/sim.log $<

$(BUILD)/sim.vvp: $(SRCS) | $(BUILD)
	$(IVERILOG) -g2012 -o $@ -s $(TOP) -P$(TOP).WIDTH=$(WIDTH) -P$(TOP).SEED=$(SEED) $(SRCS)
else
# ---- Verilator 后端：--binary 直接编译出可执行仿真器 ----
sim: $(BUILD)/V$(TOP)
	$< | tee $(BUILD)/sim.log

$(BUILD)/V$(TOP): $(SRCS) | $(BUILD)
	$(VERILATOR) --binary --timing -j 4 -Wno-fatal --Mdir $(BUILD) -GWIDTH=$(WIDTH) -GSEED=$(SEED) --top-module $(TOP) $(SRCS)
endif

# ---- 静态检查（始终走 verilator）----
lint:
	$(VERILATOR) --lint-only -Wall --timing -Wno-BLKSEQ -GWIDTH=$(WIDTH) -GSEED=$(SEED) --top-module $(TOP) $(SRCS)

# ---- 看波形（tb 里需 dumpfile/dumpvars）----
wave: $(BUILD)/dump.vcd
	gtkwave $< &

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)

# ---- 修改示范：多随机种子回归 ----
SEEDS ?= 1 2 3 4 5
regress:
	@for s in $(SEEDS); do \
	    echo "== SEED=$$s =="; \
	    $(MAKE) -s clean; \
	    $(MAKE) -s sim SEED=$$s | grep -E 'PASS|FAIL' || exit 1; \
	done
	@echo "regress done: $(words $(SEEDS)) seeds"
