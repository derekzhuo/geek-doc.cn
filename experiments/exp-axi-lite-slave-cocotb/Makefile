# axi-lite-slave lab — Icarus compile + self-checking TB (non-zero exit on FAIL)
IVERILOG ?= iverilog
VVP      ?= vvp
SRCS     := rtl/axi_lite_regs.v testbench/tb_axi_lite_regs.v
OUT      := build/sim.out

run: $(OUT)
	cd build && $(VVP) sim.out

$(OUT): $(SRCS)
	mkdir -p build
	$(IVERILOG) -g2012 -Wall -o $(OUT) $(SRCS)

synth:
	mkdir -p build
	yosys -p "read_verilog rtl/axi_lite_regs.v; synth -top axi_lite_regs; stat" \
	  2>&1 | tee build/yosys-stat.log

clean:
	rm -rf build dump.vcd

.PHONY: run synth clean
