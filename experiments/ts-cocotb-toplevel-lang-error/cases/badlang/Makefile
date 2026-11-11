# Wrong language for Icarus: VHDL on a Verilog-only simulator.
TOPLEVEL_LANG = vhdl
VHDL_SOURCES =
VERILOG_SOURCES = $(PWD)/../../counter.v
TOPLEVEL = counter
COCOTB_TEST_MODULES = test_counter

include $(shell cocotb-config --makefiles)/Makefile.sim
