# cocotb 2.1.0 minimal testbench Makefile (SIM=icarus)
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/counter.v
TOPLEVEL := counter
# cocotb 2.1 names; the old MODULE / TESTCASE variables are deprecated.
COCOTB_TEST_MODULES := test_counter

include $(shell cocotb-config --makefiles)/Makefile.sim
