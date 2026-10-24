# Template Makefile for a small EDA project.
# Targets: make run (compile+sim), make lint (verilator), make clean.
IVERILOG ?= iverilog
VERILATOR ?= verilator

RTL     = rtl/counter16.v
TB      = tb/tb_counter16.v
SIM_DIR = sim
VVP     = $(SIM_DIR)/counter16.vvp

.PHONY: run sim lint clean

run: sim

sim: $(VVP)
	vvp $(VVP)

$(VVP): $(RTL) $(TB)
	mkdir -p $(SIM_DIR)
	$(IVERILOG) -g2012 -o $(VVP) $(RTL) $(TB)

lint:
	$(VERILATOR) --lint-only -Wall $(RTL)

clean:
	rm -rf $(SIM_DIR)
