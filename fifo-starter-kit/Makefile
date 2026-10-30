SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

IVERILOG ?= iverilog
VVP      ?= vvp

OUT_DIR := out
SIMV    := $(OUT_DIR)/sim.vvp
LOG     := $(OUT_DIR)/sim.log
SOURCES := rtl/sync_fifo.v tb/tb_sync_fifo.v

.PHONY: all run test clean

all: test

run: test

test: $(SIMV)
	cd $(OUT_DIR) && $(VVP) sim.vvp 2>&1 | tee sim.log
	grep -q '^RESULT: PASS$$' $(LOG)
	@printf '\nWaveform: %s/sync_fifo.vcd\nLog:      %s\n' "$(OUT_DIR)" "$(LOG)"

$(SIMV): $(SOURCES) | $(OUT_DIR)
	$(IVERILOG) -g2012 -o $@ $(SOURCES)

$(OUT_DIR):
	mkdir -p $@

clean:
	rm -rf $(OUT_DIR)
