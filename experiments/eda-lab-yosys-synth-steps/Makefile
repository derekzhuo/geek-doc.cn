# eda-lab-yosys-synth-steps —— 把 yosys synth -top 拆成单步执行，逐步 stat 落盘
# 容器运行：docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
#   -v ~/Project/geek-doc.cn/experiments:/work -w /work/eda-lab-yosys-synth-steps \
#   geek-eda:0.1 make run

YOSYS ?= yosys
OUT    = out

.PHONY: run clean steps oneshot

run: clean steps oneshot
	@echo "==== all done, see $(OUT)/ ===="

$(OUT):
	mkdir -p $(OUT)

# ---- 逐步拆解：每个分组执行后 stat 落盘 ----
# 分组边界与 `yosys -p "help synth"`（yosys 0.33）打印的步骤序列一一对应
steps: $(OUT)
	# 0. 读入 RTL + 层次检查（对应 synth 的 begin 段）
	# 用 write_ilang/read_ilang 接力：每步从上一步的设计快照继续
	$(YOSYS) -Q -T -l $(OUT)/step_00_read.log -p \
	  "read_verilog uart_rx.v; hierarchy -check -top uart_rx; stat; write_ilang $(OUT)/s00.il"
	# 1. proc：消除过程块（always/case -> 单元与线网）
	$(YOSYS) -Q -T -l $(OUT)/step_01_proc.log -p \
	  "read_ilang $(OUT)/s00.il; proc; stat; write_ilang $(OUT)/s01.il"
	# 2. 表达式/清理 + 初次 opt（对应 coarse 段 opt_expr; opt_clean; check; opt -nodffe -nosdff）
	$(YOSYS) -Q -T -l $(OUT)/step_02_opt1.log -p \
	  "read_ilang $(OUT)/s01.il; opt_expr; opt_clean; check; opt -nodffe -nosdff; stat; write_ilang $(OUT)/s02.il"
	# 3. fsm：状态机提取与编码优化
	$(YOSYS) -Q -T -l $(OUT)/step_03_fsm.log -p \
	  "read_ilang $(OUT)/s02.il; fsm; stat; write_ilang $(OUT)/s03.il"
	# 4. 位宽削减与窥孔优化（对应 opt; wreduce; peepopt; opt_clean）
	$(YOSYS) -Q -T -l $(OUT)/step_04_wreduce.log -p \
	  "read_ilang $(OUT)/s03.il; opt; wreduce; peepopt; opt_clean; stat; write_ilang $(OUT)/s04.il"
	# 5. 算术单元抽取与资源共享（对应 alumacc; share; opt）
	$(YOSYS) -Q -T -l $(OUT)/step_05_share.log -p \
	  "read_ilang $(OUT)/s04.il; alumacc; share; opt; stat; write_ilang $(OUT)/s05.il"
	# 6. 存储器识别（对应 memory -nomap; opt_clean）
	$(YOSYS) -Q -T -l $(OUT)/step_06_memory.log -p \
	  "read_ilang $(OUT)/s05.il; memory -nomap; opt_clean; stat; write_ilang $(OUT)/s06.il"
	# 7. fine 段前半：快速全量优化 + memory_map + 全量优化
	$(YOSYS) -Q -T -l $(OUT)/step_07_fine.log -p \
	  "read_ilang $(OUT)/s06.il; opt -fast -full; memory_map; opt -full; stat; write_ilang $(OUT)/s07.il"
	# 8. techmap：通用门级映射（ techmap 无参，映射到 $logic 等内部单元 ）
	$(YOSYS) -Q -T -l $(OUT)/step_08_techmap.log -p \
	  "read_ilang $(OUT)/s07.il; techmap; stat; write_ilang $(OUT)/s08.il"
	# 9. abc 优化 + 收尾（对应 opt -fast; abc -fast; opt -fast）
	$(YOSYS) -Q -T -l $(OUT)/step_09_abc.log -p \
	  "read_ilang $(OUT)/s08.il; opt -fast; abc -fast; opt -fast; stat; write_ilang $(OUT)/s09.il"
	# 10. check 段：hierarchy -check; stat; check（最终报表）
	$(YOSYS) -Q -T -l $(OUT)/step_10_check.log -p \
	  "read_ilang $(OUT)/s09.il; hierarchy -check; stat; check"
	# 汇总：从各步日志抽取关键行
	grep -H -E "Number of (cells|wires|memories|processes)" $(OUT)/step_*.log \
	  > $(OUT)/stat_summary.txt || true

# ---- 一把梭：synth -top uart_rx 对照组 ----
oneshot: $(OUT)
	$(YOSYS) -Q -T -l $(OUT)/oneshot_synth.log -p \
	  "read_verilog uart_rx.v; synth -top uart_rx"

clean:
	rm -rf $(OUT)
