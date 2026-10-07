# eda-lab-iverilog-vcd-wave —— $dumpvars 层级/范围控制对 VCD 大小的影响
# 环境：geek-eda:0.1 容器（Icarus Verilog 12.0 / Ubuntu 24.04）
# 运行：make run

IVERILOG := iverilog
VVP      := vvp

all: run

run: full.vcd slim.vcd report
	@echo "==== 全部完成 ===="

full.vcd: counter.v tb_full.v
	$(IVERILOG) -g2012 -o sim_full.vvp counter.v tb_full.v
	$(VVP) sim_full.vvp | tee run_full.log

slim.vcd: counter.v tb_slim.v
	$(IVERILOG) -g2012 -o sim_slim.vvp counter.v tb_slim.v
	$(VVP) sim_slim.vvp | tee run_slim.log

report: full.vcd slim.vcd
	@echo "==== VCD 文件大小对比 ====" | tee report.txt
	@ls -l full.vcd slim.vcd | tee -a report.txt
	@echo "" | tee -a report.txt
	@echo "full.vcd 行数 / 跳变块统计：" | tee -a report.txt
	@wc -l full.vcd | tee -a report.txt
	@echo "slim.vcd 行数：" | tee -a report.txt
	@wc -l slim.vcd | tee -a report.txt
	@echo "" | tee -a report.txt
	@echo "full.vcd 中声明的信号数（\$$var 行）：" | tee -a report.txt
	@grep -c '^\$$var' full.vcd | tee -a report.txt
	@echo "slim.vcd 中声明的信号数：" | tee -a report.txt
	@grep -c '^\$$var' slim.vcd | tee -a report.txt

# 从 full.vcd 提取前若干 ns 内顶层信号的跳变，供 wavedrom 校对
wavecheck: full.vcd
	@echo "---- full.vcd 头部定义 ----"
	@sed -n '1,40p' full.vcd
	@echo "---- 前 300ns 内的跳变（截取） ----"
	@awk '/^#0/{f=1} f&&/^#300/{exit} f' full.vcd | head -60

clean:
	rm -f *.vvp *.vcd *.log report.txt

.PHONY: all run report wavecheck clean
