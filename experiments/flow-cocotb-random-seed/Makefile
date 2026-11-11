# cocotb 2.1.0, Icarus Verilog 12.0 (geek-eda:0.3-sta)
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# DUT_FILE lets the regression script swap in the boundary-bug variant.
DUT_FILE ?= sat_add8.v
VERILOG_SOURCES += $(PWD)/$(DUT_FILE)
TOPLEVEL := sat_add8
COCOTB_TEST_MODULES := test_sat_add

include $(shell cocotb-config --makefiles)/Makefile.sim
