TOP := blink
BUILD_DIR := build
RTL := rtl/blink.v
PCF := constraints/blink.pcf
JSON := $(BUILD_DIR)/$(TOP).json
ASC := $(BUILD_DIR)/$(TOP).asc
BIN := $(BUILD_DIR)/$(TOP).bin

DEVICE := hx1k
PACKAGE := tq144
FREQ_MHZ := 12
SEED := 1

YOSYS ?= yosys
NEXTPNR ?= nextpnr-ice40
ICEPACK ?= icepack
