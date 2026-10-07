# Makefile —— cocotb 2.1.0 + icarus 标准写法（上半段），
# 下半段是回归脚本：多 seed 回归 + 故意注错演示一次真实 FAIL。

SIM             ?= icarus
TOPLEVEL_LANG   ?= verilog
VERILOG_SOURCES  = $(PWD)/counter.v
TOPLEVEL         = counter
MODULE           = test_counter

# cocotb 标准尾巴：一行 include 引入官方 Makefile.sim，
# 编译/运行/清理规则全部由它提供。
include $(shell cocotb-config --makefiles)/Makefile.sim

# ---------- 以下为自定义回归目标 ----------

SEEDS ?= 1 2 3 4 5

.PHONY: run regress failcase clean-all

run: regress failcase
	@echo "=== all artifacts in out/ ==="

# 多 seed 回归：每个 seed 独立跑一轮完整仿真，JUnit XML 与日志分文件落盘。
regress:
	@mkdir -p out
	@echo "seed | tests | failures | result" | tee out/regression.md
	@echo "---|---|---|---" | tee -a out/regression.md
	@for s in $(SEEDS); do \
	  rm -rf sim_build; \
	  RANDOM_SEED=$$s COCOTB_RESULTS_FILE=out/results_seed$$s.xml \
	    $(MAKE) sim > out/seed$$s.log 2>&1; \
	  rc=$$?; \
	  tests=$$(grep -o '<testcase' out/results_seed$$s.xml | wc -l); \
	  fails=$$(grep -o '<failure' out/results_seed$$s.xml | wc -l); \
	  if [ $$rc -eq 0 ]; then r=PASS; else r=FAIL; fi; \
	  echo "$$s | $$tests | $$fails | $$r" | tee -a out/regression.md; \
	done
	@cat out/seed1.log > out/sim.log

# 注错演示：参考模型复位初值故意写成 1（off-by-one），必然 FAIL。
failcase:
	@mkdir -p out
	@rm -rf sim_build
	@-RANDOM_SEED=1 INJECT_BUG=1 COCOTB_RESULTS_FILE=out/results_fail.xml \
	  $(MAKE) sim > out/fail.log 2>&1
	@echo "failcase log -> out/fail.log (exit non-zero expected)"

clean-all: clean
	rm -rf out sim_build
