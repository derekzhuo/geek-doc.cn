# constraints.xdc —— Xilinx Vivado 约束模板（管脚号按你的开发板原理图替换！）
# Intel Quartus 用 .qsf/.sdc，思路相同：一条时钟约束 + 每个端口的管脚绑定。

# 1) 时钟约束：告诉工具 clk 的周期（50MHz => 20ns）。这是时序分析的基准。
set_property PACKAGE_PIN W5 [get_ports clk]
create_clock -name sys_clk -period 20.000 [get_ports clk]

# 2) 复位按键（低有效）与 LED 的物理管脚
set_property PACKAGE_PIN U18 [get_ports rst_n]
set_property PACKAGE_PIN H17 [get_ports led]

# 3) IO 电平标准（按板卡，常见 LVCMOS33）
set_property IOSTANDARD LVCMOS33 [get_ports *]
