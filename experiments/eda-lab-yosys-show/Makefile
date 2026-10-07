# eda-lab yosys 端到端样例：RTL → 综合 → 网表图 SVG + stat 报表
# 依赖：yosys（brew install yosys）、graphviz（brew install graphviz，提供 dot）
OUT := out

.PHONY: run clean
run: $(OUT)/netlist_rtl.svg $(OUT)/netlist_gate.svg $(OUT)/stat.txt
	@echo '--- 产物 ---'
	@ls -la $(OUT)

$(OUT):
	mkdir -p $(OUT)

# 1) read_verilog + hierarchy 后直接出图：RTL 级（寄存器/运算器形态）
$(OUT)/netlist_rtl.dot: counter.v | $(OUT)
	yosys -p 'read_verilog counter.v; hierarchy -top counter; proc; show -format dot -prefix $(OUT)/netlist_rtl' 2>&1 | tee $(OUT)/show_rtl.log

# 2) 完整综合后出图：门级（标准单元形态）
$(OUT)/netlist_gate.dot: counter.v | $(OUT)
	yosys -p 'read_verilog counter.v; synth -top counter; show -format dot -prefix $(OUT)/netlist_gate' 2>&1 | tee $(OUT)/show_gate.log

$(OUT)/netlist_rtl.svg: $(OUT)/netlist_rtl.dot
	dot -Tsvg $< -o $@

$(OUT)/netlist_gate.svg: $(OUT)/netlist_gate.dot
	dot -Tsvg $< -o $@

# 3) 综合统计报表：单元数/线网数/触发器数
$(OUT)/stat.txt: counter.v | $(OUT)
	yosys -p 'read_verilog counter.v; synth -top counter; stat' 2>&1 | tee $(OUT)/stat.log
	awk '/^=== counter ===/{p=1; buf=""} p{buf=buf $$0 ORS} END{printf "%s", buf}' $(OUT)/stat.log > $@

clean:
	rm -rf $(OUT)
