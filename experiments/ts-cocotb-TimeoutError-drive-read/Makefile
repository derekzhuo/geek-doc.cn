# cocotb + icarus 最小复现
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(PWD)/rtl/async_fifo.v
TOPLEVEL = async_fifo
MODULE = test_async_fifo_timeout
COMPILE_ARGS = -g2012

export COCOTB_HDL_TIMEUNIT = 1ns
export COCOTB_HDL_TIMEPRECISION = 1ps
export PYTHONPATH := $(PWD)/testbench:$(PYTHONPATH)

include $(shell cocotb-config --makefiles)/Makefile.sim

run: sim
