# crc8 实验：iverilog 编译 + vvp 回归
IVERILOG ?= iverilog
VVP      ?= vvp
TOP      := tb_crc8
SRC      := tb_crc8.sv crc8_serial.sv

.PHONY: all run clean
all: run
$(TOP).vvp: $(SRC)
	$(IVERILOG) -g2012 -o $@ $(SRC)
run: $(TOP).vvp
	$(VVP) $(TOP).vvp | tee run1.log
clean:
	rm -f $(TOP).vvp *.vcd
