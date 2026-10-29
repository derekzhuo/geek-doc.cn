.PHONY: run broken fixed

run:
	@bash run.sh

broken:
	verilator --lint-only -Wall widthtrunc_broken.sv

fixed:
	verilator --lint-only -Wall widthtrunc_fixed.sv
