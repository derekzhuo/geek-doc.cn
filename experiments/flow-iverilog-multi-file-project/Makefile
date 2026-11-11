# 三模块工程（alu + regfile + datapath）三种文件组织方式
# make cli    命令行直接列文件
# make flist  -f filelist.f 读清单
# make lib    -y rtl 库目录自动检索
# make run    三种方式依次全跑
# make clean

IVERILOG := iverilog
VVP      := vvp
BUILD    := build
TOP_TB   := tb/tb_top.v
SRCS     := rtl/alu.v rtl/regfile.v rtl/datapath.v $(TOP_TB)

.PHONY: all cli flist lib run clean
all: cli

$(BUILD):
	mkdir -p $(BUILD)

cli: | $(BUILD)
	$(IVERILOG) -g2012 -Wall -o $(BUILD)/sim_cli.vvp $(SRCS)
	$(VVP) $(BUILD)/sim_cli.vvp

flist: | $(BUILD)
	$(IVERILOG) -g2012 -Wall -o $(BUILD)/sim_flist.vvp -f filelist.f
	$(VVP) $(BUILD)/sim_flist.vvp

lib: | $(BUILD)
	$(IVERILOG) -g2012 -Wall -o $(BUILD)/sim_lib.vvp -y rtl $(TOP_TB)
	$(VVP) $(BUILD)/sim_lib.vvp

run:
	bash run.sh

clean:
	rm -rf $(BUILD)
