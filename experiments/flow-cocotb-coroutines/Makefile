SIM ?= icarus
TOPLEVEL_LANG ?= verilog

COMPILE_ARGS += -g2012

VERILOG_SOURCES += $(PWD)/pipe_delay.v
TOPLEVEL := pipe_delay
COCOTB_TEST_MODULES := test_pipe

include $(shell cocotb-config --makefiles)/Makefile.sim
