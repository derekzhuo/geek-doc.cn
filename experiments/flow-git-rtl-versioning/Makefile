RTL   := rtl/counter4.v
TB    := tb/tb_counter4.v
BUILD := build
SIM   := $(BUILD)/sim.vvp

.PHONY: sim clean
sim: $(SIM)
	vvp -n $(SIM)

$(SIM): $(RTL) $(TB)
	mkdir -p $(BUILD)
	iverilog -g2012 -Wall -o $@ $(TB) $(RTL)

clean:
	rm -rf $(BUILD)
