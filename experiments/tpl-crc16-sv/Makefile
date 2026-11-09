# crc16 实验：iverilog 编译 + vvp 回归
IVERILOG ?= iverilog
VVP      ?= vvp
TOP      := tb_crc16
SRC      := tb_crc16.sv crc16.sv

.PHONY: all run clean
all: run
$(TOP).vvp: $(SRC)
	$(IVERILOG) -g2012 -o $@ $(SRC)
run: $(TOP).vvp
	$(VVP) $(TOP).vvp | tee run1.log
clean:
	rm -f $(TOP).vvp *.vcd
