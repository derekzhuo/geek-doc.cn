# async-fifo lab — cocotb over Icarus Verilog, FST waveform for doc assets
SIM      ?= icarus
WAVES    ?= 1
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(wildcard rtl/*.v)
TOPLEVEL = async_fifo
MODULE   = test_async_fifo
COMPILE_ARGS = -g2012
# iverilog 默认 timescale 1s/1s，cocotb 的 ns 级 Clock 会因精度不足直接 FAIL
export COCOTB_HDL_TIMEUNIT ?= 1ns
export COCOTB_HDL_TIMEPRECISION ?= 1ps
COCOTB_VENV ?= /opt/eda-venv

run:
	PATH=$(COCOTB_VENV)/bin:$$PATH PYTHONPATH=testbench \
	  $(MAKE) -f $(shell python3 $(COCOTB_VENV)/bin/cocotb-config --makefiles)/Makefile.sim \
	  SIM=$(SIM) WAVES=$(WAVES) TOPLEVEL_LANG=$(TOPLEVEL_LANG) \
	  VERILOG_SOURCES="$(VERILOG_SOURCES)" TOPLEVEL=$(TOPLEVEL) MODULE=$(MODULE) COMPILE_ARGS="$(COMPILE_ARGS)"

clean:
	rm -rf sim_build results.xml __pycache__ testbench/__pycache__ dump.fst

.PHONY: run clean
