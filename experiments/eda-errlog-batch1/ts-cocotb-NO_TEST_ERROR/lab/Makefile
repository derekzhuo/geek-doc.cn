SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES = rtl/async_fifo.v
TOPLEVEL = async_fifo
MODULE = test_async_fifo
COMPILE_ARGS = -g2012
WAVES = 1
export PYTHONPATH := testbench:$(PYTHONPATH)

include $(shell cocotb-config --makefiles)/Makefile.sim
