# Minimal cocotb Makefile (official makefile flow), SIM=icarus
SIM            ?= icarus
TOPLEVEL_LANG  ?= verilog

VERILOG_SOURCES = $(shell pwd)/counter.v
TOPLEVEL        = counter
MODULE          = test_counter

include $(shell cocotb-config --makefiles)/Makefile.sim
