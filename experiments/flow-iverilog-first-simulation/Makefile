# 最小仿真闭环：iverilog 编译 -> vvp 运行 -> 产出 wave.vcd
VVP  = sim.vvp
SRCS = counter.v tb_counter.v

.PHONY: all run clean

all: run

$(VVP): $(SRCS)
	iverilog -g2012 -Wall -o $(VVP) $(SRCS)

run: $(VVP)
	vvp $(VVP)

clean:
	rm -f $(VVP) wave.vcd
