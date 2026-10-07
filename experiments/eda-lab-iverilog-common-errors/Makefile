# eda-lab-iverilog-common-errors：依次触发 4 类 iverilog 常见报错并收集真实输出
# 每条命令预期失败，日志落 out/*.log

IVERILOG := iverilog
OUT := out

.PHONY: run clean

run: $(OUT)/syntax.log $(OUT)/undeclared.log $(OUT)/port.log $(OUT)/unknown_module.log
	@echo "== all logs collected =="
	@ls -l $(OUT)

$(OUT):
	mkdir -p $(OUT)

$(OUT)/syntax.log: err_syntax_semicolon.v | $(OUT)
	-$(IVERILOG) -o $(OUT)/syntax.vvp $< 2>&1 | tee $@

$(OUT)/undeclared.log: err_undeclared.v | $(OUT)
	-$(IVERILOG) -o $(OUT)/undeclared.vvp $< 2>&1 | tee $@

$(OUT)/port.log: err_port.v | $(OUT)
	-$(IVERILOG) -g2005 -Wall -o $(OUT)/port.vvp $< 2>&1 | tee $@

$(OUT)/unknown_module.log: err_unknown_module.v | $(OUT)
	-$(IVERILOG) -o $(OUT)/unknown.vvp $< 2>&1 | tee $@

version:
	$(IVERILOG) -V | head -1 | tee $(OUT)/version.log

clean:
	rm -rf $(OUT)
