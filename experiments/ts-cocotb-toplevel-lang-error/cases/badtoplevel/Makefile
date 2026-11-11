TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(PWD)/../../counter.v
# Mismatch: the RTL module is named "counter", not "counter_top".
TOPLEVEL = counter_top
COCOTB_TEST_MODULES = test_counter

include $(shell cocotb-config --makefiles)/Makefile.sim
