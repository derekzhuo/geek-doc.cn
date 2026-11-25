SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:

include toolchain.mk

.PHONY: all clean verify versions ci

all: $(BIN)

$(BUILD_DIR):
	mkdir -p $@

$(JSON): $(RTL) Makefile toolchain.mk | $(BUILD_DIR)
	$(YOSYS) -l $(BUILD_DIR)/yosys.log -p 'synth_ice40 -top $(TOP) -json $@' $(RTL)

$(ASC): $(JSON) $(PCF) Makefile toolchain.mk | $(BUILD_DIR)
	$(NEXTPNR) --$(DEVICE) --package $(PACKAGE) --json $(JSON) --pcf $(PCF) --asc $@ --freq $(FREQ_MHZ) --seed $(SEED) --log $(BUILD_DIR)/nextpnr.log

$(BIN): $(ASC) Makefile toolchain.mk
	$(ICEPACK) $< $@

verify: $(BIN)
	@test -s $(JSON)
	@test -s $(ASC)
	@test -s $(BIN)
	@sha256sum $(JSON) $(ASC) $(BIN)

versions:
	@$(YOSYS) -V
	@$(NEXTPNR) --version
	@dpkg-query -W -f='fpga-icestorm $${Version}\n' fpga-icestorm

ci:
	$(MAKE) clean
	$(MAKE) --no-builtin-rules all
	$(MAKE) verify

clean:
	rm -rf $(BUILD_DIR)
