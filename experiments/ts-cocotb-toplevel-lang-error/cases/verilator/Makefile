TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(PWD)/../../counter.v
TOPLEVEL = counter
COCOTB_TEST_MODULES = test_counter

# Selected with: make SIM=verilator
# cocotb 2.1.0 requires Verilator >= 5.036; the image ships 5.020.
include $(shell cocotb-config --makefiles)/Makefile.sim
