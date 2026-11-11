# cocotb 2.1.0 minimal Makefile (SIM = Icarus Verilog)
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/dff.v
TOPLEVEL := dff
COCOTB_TEST_MODULES := test_dff

include $(shell cocotb-config --makefiles)/Makefile.sim
