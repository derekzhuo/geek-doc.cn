IMG ?= geek-eda:0.3-sta
DRUN = docker run --rm -v "$(PWD)":/work -w /work $(IMG)

.PHONY: run synth sdf presim gatesim clean

run: ## 全流程：综合 + SDF + 前仿 + 门级后仿
	bash run.sh

synth: ## RTL -> Yosys generic 门级网表
	$(DRUN) yosys -s synth.ys

sdf: synth ## 从网表生成教学用最小 SDF
	$(DRUN) bash -c "awk -f gen_sdf.awk netlist.v > counter.sdf"

presim: ## RTL 零延时前仿
	$(DRUN) bash -c "iverilog -o pre.vvp counter.v tb_counter.v && vvp pre.vvp"

gatesim: sdf ## SDF 反标门级后仿
	$(DRUN) bash -c "iverilog -g2012 -gspecify -DGATES -o gate.vvp gates_sim.v netlist.v tb_counter.v && vvp gate.vvp"

clean:
	rm -f netlist.v pre.vvp gate.vvp
