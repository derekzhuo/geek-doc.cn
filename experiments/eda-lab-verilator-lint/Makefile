# eda-lab-verilator-lint：问题 RTL 跑 verilator --lint-only，收集真实告警并演示 waiver
# 日志全部落 out/，lint 命令预期非零退出，前面加 "-" 放行

VERILATOR := verilator
OUT := out

.PHONY: run clean version

run: $(OUT)/default.log $(OUT)/lint.log $(OUT)/waived.log $(OUT)/vlt.log
	@echo "== all logs collected =="
	@ls -l $(OUT)

$(OUT):
	mkdir -p $(OUT)

version: | $(OUT)
	$(VERILATOR) --version | tee $(OUT)/version.log

# 1. 默认告警集（不加 -Wall）：只有默认开启的告警
$(OUT)/default.log: lint_demo.v | $(OUT)
	-$(VERILATOR) --lint-only lint_demo.v > $@ 2>&1; \
		echo "exit_code=$$?" >> $@

# 2. -Wall 全开告警：本文主日志，6 类问题应全部现身
$(OUT)/lint.log: lint_demo.v | $(OUT)
	-$(VERILATOR) --lint-only -Wall lint_demo.v > $@ 2>&1; \
		echo "exit_code=$$?" >> $@

# 3. waiver 方式一：源码内 lint_off 注释（WIDTH/UNOPTFLAT 被豁免，另修复了一处 WIDTH）
$(OUT)/waived.log: lint_demo_waived.v | $(OUT)
	-$(VERILATOR) --lint-only -Wall lint_demo_waived.v > $@ 2>&1; \
		echo "exit_code=$$?" >> $@

# 4. waiver 方式二：.vlt 配置文件（CASEINCOMPLETE/UNUSED/UNDRIVEN 集中豁免）
$(OUT)/vlt.log: lint_demo.v lint_off/waivers.vlt | $(OUT)
	-$(VERILATOR) --lint-only -Wall lint_off/waivers.vlt lint_demo.v > $@ 2>&1; \
		echo "exit_code=$$?" >> $@

clean:
	rm -rf $(OUT)
