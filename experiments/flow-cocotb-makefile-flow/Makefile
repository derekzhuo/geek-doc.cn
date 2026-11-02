# cocotb 2.1 Makefile for the counter DUT; every variable is exercised
# by run.sh scenarios.
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(CURDIR)/counter.v
TOPLEVEL := counter

# cocotb 2.1 name for the python test module(s); legacy MODULE is an alias.
COCOTB_TEST_MODULES ?= test_counter

# COMPILE_ARGS must be appended with += inside the Makefile: a command-line
# "COMPILE_ARGS=..." override wipes cocotb's own compile args (notably
# -f sim_build/cmds.f carrying +timescale+1ns/1ps).
WIDTH ?=
ifneq ($(WIDTH),)
COMPILE_ARGS += -Pcounter.WIDTH=$(WIDTH)
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
