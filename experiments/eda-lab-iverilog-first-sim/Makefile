# Makefile —— iverilog 仿真入门实验
# make run：编译 → 运行 → 生成 out/counter.vcd，并把日志存到 out/sim.log

IVERILOG ?= iverilog
VVP      ?= vvp

SIMV     := out/counter_sim.vvp
VCD      := out/counter.vcd
LOG      := out/sim.log

.PHONY: run clean

run: $(VCD)

$(SIMV): counter.v counter_tb.v | out
	$(IVERILOG) -g2012 -o $@ counter.v counter_tb.v

$(VCD): $(SIMV)
	$(VVP) $(SIMV) | tee $(LOG)

out:
	mkdir -p out

clean:
	rm -rf out
