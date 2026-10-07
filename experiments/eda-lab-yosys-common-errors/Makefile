# eda-lab-yosys-common-errors：真实触发 yosys 四类常见报错并收集输出
# 用法：make run（在 geek-eda:0.1 容器内执行）
YOSYS ?= yosys
OUT   := out

.PHONY: run clean
run: $(OUT) err1_undeclared err2_multidriver err3_sv_syntax err4_combloop ok_fixed
	@echo "==== all logs collected in $(OUT)/ ===="

$(OUT):
	mkdir -p $(OUT)

err1_undeclared:
	@echo "== [1/5] default_nettype none 下未声明线网 =="
	-$(YOSYS) -Q -T -p "read_verilog err_undeclared.v" > $(OUT)/err1_undeclared.log 2>&1; \
	  echo "exit=$$?" >> $(OUT)/err1_undeclared.log
	@cat $(OUT)/err1_undeclared.log

err2_multidriver:
	@echo "== [2/5] 多驱动同一信号 =="
	-$(YOSYS) -Q -T -p "read_verilog err_multidriver.v; hierarchy -top dual_drive; proc; check" > $(OUT)/err2_multidriver.log 2>&1; \
	  echo "exit=$$?" >> $(OUT)/err2_multidriver.log
	@cat $(OUT)/err2_multidriver.log

err3_sv_syntax:
	@echo "== [3/5] SystemVerilog 语法不加 -sv =="
	-$(YOSYS) -Q -T -p "read_verilog err_sv_syntax.v" > $(OUT)/err3_sv_no_sv.log 2>&1; \
	  echo "exit=$$?" >> $(OUT)/err3_sv_no_sv.log
	@cat $(OUT)/err3_sv_no_sv.log
	@echo "-- 处置：加 -sv 重读 --"
	-$(YOSYS) -Q -T -p "read_verilog -sv err_sv_syntax.v; hierarchy -top sv_counter; stat" > $(OUT)/err3_sv_fixed.log 2>&1; \
	  echo "exit=$$?" >> $(OUT)/err3_sv_fixed.log
	@grep -E "exit=|ERROR|Warning|Number of cells" $(OUT)/err3_sv_fixed.log || true

err4_combloop:
	@echo "== [4/5] 组合逻辑环 =="
	-timeout 60 $(YOSYS) -Q -T -p "read_verilog err_combloop.v; hierarchy -top comb_loop; synth -top comb_loop; check" > $(OUT)/err4_combloop.log 2>&1; \
	  echo "exit=$$?" >> $(OUT)/err4_combloop.log
	@cat $(OUT)/err4_combloop.log

ok_fixed:
	@echo "== [5/5] 修复版对照（应全部通过） =="
	-$(YOSYS) -Q -T -p "read_verilog ok_fixed.v; read_verilog -sv err_sv_syntax.v; hierarchy -top ok_fixed; synth -top ok_fixed; check; stat" > $(OUT)/ok_fixed.log 2>&1; \
	  echo "exit=$$?" >> $(OUT)/ok_fixed.log
	@grep -E "exit=|ERROR|Warning|found and reported|Number of" $(OUT)/ok_fixed.log || true

clean:
	rm -rf $(OUT)
