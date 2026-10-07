# Makefile —— verilator --binary vs iverilog 速度对比实验
# make run        : 编译两套仿真器 → 各跑 3 次计时 → 中位数写入 out/timing.log
# make run-fast   : 只各跑 1 次（冒烟用）
# make lint-err   : 复现「不加 --timing 时 verilator 的报错」（教学用，会失败退出）

IVERILOG  ?= iverilog
VVP       ?= vvp
VERILATOR ?= verilator

CYCLES    ?= 10000000
RUNS      ?= 3

SIMV      := out/counter_sim.vvp
VBIN      := obj_dir/Vcounter_tb
LOG       := out/timing.log

.PHONY: run run-fast build-iverilog build-verilator lint-err clean

run: build-iverilog build-verilator | out
	RUNS=$(RUNS) bash scripts/timing.sh $(CYCLES) | tee $(LOG)

run-fast:
	$(MAKE) run RUNS=1

build-iverilog: | out
	$(IVERILOG) -g2012 -DCYCLES=$(CYCLES) -o $(SIMV) counter.v counter_tb.v

build-verilator:
	$(VERILATOR) --binary --timing -j 0 -DCYCLES=$(CYCLES) \
	    -o Vcounter_tb counter.v counter_tb.v 2>&1 | tee out/verilator_build.log

# 教学复现：本实验真实踩过的三个坑（各产一份报错日志到 out/）
# 坑 1：--lint-only 不带 --timing 编译含 # 延迟的 TB → NEEDTIMINGOPT
# 坑 2：无 timescale 的模块排在带 timescale 的模块之前 → TIMESCALEMOD（warning 当 error 退出）
# 坑 3：注释以「verilator 」开头被当成 lint pragma → Unknown verilator comment
lint-err: | out
	-@$(VERILATOR) --lint-only counter_tb.v counter.v \
	    > out/err-needtiming.log 2>&1
	@echo "---- out/err-needtiming.log ----"
	@cat out/err-needtiming.log
	-@$(VERILATOR) --binary -DCYCLES=1000 pitfall/counter_no_ts.v counter_tb.v \
	    > out/err-timescale.log 2>&1
	@echo "---- out/err-timescale.log ----"
	@cat out/err-timescale.log
	-@$(VERILATOR) --lint-only pitfall/metacomment.v \
	    > out/err-metacomment.log 2>&1
	@echo "---- out/err-metacomment.log ----"
	@cat out/err-metacomment.log

out:
	mkdir -p out

clean:
	rm -rf out obj_dir
