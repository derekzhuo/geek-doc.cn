# eda-lab-yosys-stat-report：yosys stat 报表实验
# 容器：docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
#   -v ~/Project/geek-doc.cn/experiments:/work \
#   -w /work/eda-lab-yosys-stat-report geek-eda:0.1 make run

YOSYS = yosys
OUT   = out

BAUD_SRC = baud_top.v baud_clk_div.v baud_bit_cnt.v baud_tx_fsm.v

.PHONY: run clean

run: $(OUT) $(OUT)/version.txt $(OUT)/stat_counter.txt $(OUT)/stat_baud_flat.txt \
     $(OUT)/stat_baud_hier.txt $(OUT)/stat_baud_fsm_sel.txt \
     $(OUT)/stat_div.txt $(OUT)/stat_fsm.txt
	@echo "=== ALL DONE: out/*.txt ==="
	@ls -l $(OUT)

$(OUT):
	mkdir -p $(OUT)

$(OUT)/version.txt: | $(OUT)
	$(YOSYS) -V > $@

# 实验一：计数器 synth 后 stat（通用单元）
$(OUT)/stat_counter.txt: counter.v | $(OUT)
	$(YOSYS) -p 'read_verilog counter.v; synth -top counter; tee -o $@ stat' \
	  > $(OUT)/synth_counter.log 2>&1

# 实验二：多模块设计打平后的整表
$(OUT)/stat_baud_flat.txt: $(BAUD_SRC) | $(OUT)
	$(YOSYS) -p 'read_verilog $(BAUD_SRC); synth -top baud_top -flatten; tee -o $@ stat' \
	  > $(OUT)/synth_baud_flat.log 2>&1

# 实验三：保留层级，stat 自带各模块分表
$(OUT)/stat_baud_hier.txt: $(BAUD_SRC) | $(OUT)
	$(YOSYS) -p 'read_verilog $(BAUD_SRC); synth -top baud_top; tee -o $@ stat' \
	  > $(OUT)/synth_baud_hier.log 2>&1

# 实验四：层级设计里用 select 只看单个子模块的 stat
$(OUT)/stat_baud_fsm_sel.txt: $(BAUD_SRC) | $(OUT)
	$(YOSYS) -p 'read_verilog $(BAUD_SRC); synth -top baud_top; select baud_tx_fsm; tee -o $@ stat' \
	  > $(OUT)/synth_baud_fsmsel.log 2>&1

# 实验五：单模块各自 synth 的 stat（与层级报表对照）
$(OUT)/stat_div.txt: baud_clk_div.v | $(OUT)
	$(YOSYS) -p 'read_verilog baud_clk_div.v; synth -top baud_clk_div; tee -o $@ stat' \
	  > $(OUT)/synth_div.log 2>&1

$(OUT)/stat_fsm.txt: baud_tx_fsm.v | $(OUT)
	$(YOSYS) -p 'read_verilog baud_tx_fsm.v; synth -top baud_tx_fsm; tee -o $@ stat' \
	  > $(OUT)/synth_fsm.log 2>&1

clean:
	rm -rf $(OUT)
