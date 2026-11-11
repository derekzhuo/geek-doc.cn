# 硬件最小工程 Makefile：sim（iverilog 仿真）/ synth（容器内 yosys 综合）/ clean
# 约定：源文件清单用变量集中管理，仿真输入走 filelist（src.f）

RTL_FILES := rtl/counter4.v
TB        := tb/tb_counter.v
FILELIST  := src.f
TOPLEVEL  := counter4
BUILD_DIR := build

SIM_OUT := $(BUILD_DIR)/sim.vvp
NETLIST := $(BUILD_DIR)/$(TOPLEVEL).netlist.v

IVFLAGS := -g2012 -Wall
EDA_IMG := geek-eda:0.4-flow
# $$PWD 交给 shell 展开，make 回显与 yosys 日志里都不会出现宿主机绝对路径
DOCKER   = docker run --rm -v "$$PWD":/work -w /work $(EDA_IMG)

.PHONY: all sim synth lint wave clean help
all: sim

# 仿真字节码：依赖 RTL、TB 与 filelist，任一改动才重新编译
$(SIM_OUT): $(RTL_FILES) $(TB) $(FILELIST)
	mkdir -p $(BUILD_DIR)
	iverilog $(IVFLAGS) -o $@ -f $(FILELIST)

# sim 是动作目标：编译产物过期就先编译，然后 vvp 运行
sim: $(SIM_OUT)
	vvp -n $(SIM_OUT)

# 只做语法检查，不落仿真产物
lint:
	iverilog $(IVFLAGS) -tnull -f $(FILELIST)

# 综合在 geek-eda 容器内执行，网表与日志落 build/
$(NETLIST): $(RTL_FILES)
	mkdir -p $(BUILD_DIR)
	$(DOCKER) yosys -p "read_verilog $(RTL_FILES); synth -top $(TOPLEVEL); stat; write_verilog $(NETLIST)"

synth: $(NETLIST)

# 波形目标（本机装有 gtkwave 时使用）
wave: sim
	gtkwave $(BUILD_DIR)/wave.vcd

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "targets: sim synth lint wave clean"
