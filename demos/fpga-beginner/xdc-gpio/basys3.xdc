# basys3.xdc —— Xilinx Vivado 约束（XDC）示例
# 配套 fpga/beginner/05-xdc-constraints-intro.md
# 板卡：Digilent Basys3（Artix-7 XC7A35T-1CPG236C）。管脚号取自 Digilent 官方 master XDC。
# 其它板子（Arty/Nexys/自研板）：管脚号必须换成你板子 master XDC / 原理图里的值，照搬会点不亮甚至报错。
#
# XDC 里两类约束：
#   物理约束(PACKAGE_PIN/IOSTANDARD)——告诉工具每个端口接到芯片哪个脚、什么电平；
#   时序约束(create_clock)——告诉工具时钟多快，是 STA 时序分析的基准。
# 一个最小能跑的工程，这两类都不能少。

# ========== 1) 时钟：物理管脚 + 时序约束（缺一不可）==========
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
# 100MHz => 周期 10ns。这一句是静态时序分析(STA)的基准，少了它工具不知道时钟多快。
create_clock -name sys_clk -period 10.000 [get_ports clk]

# ========== 2) 复位按键（高有效，按下=1）==========
# Basys3 中央按键 btnC
set_property PACKAGE_PIN N17 [get_ports btn]
set_property IOSTANDARD LVCMOS33 [get_ports btn]

# ========== 3) 8 位拨码开关输入 ==========
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports sw*]

# ========== 4) 16 位 LED 输出 ==========
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports led*]

# ---- 提示 ----
# * 总线位用花括号：get_ports {sw[0]}；整组可写 get_ports {sw[*]}。
# * 别忘了每个端口都要有 IOSTANDARD；3.3V 单端 IO 一般是 LVCMOS33。
# * 时钟除了 PACKAGE_PIN，还必须 create_clock——只有管脚、没有时钟约束，时序报告是不可信的。
# * 本设计全是慢信号(开关/1Hz 心跳)，即使时序基准很宽松也一定 met；高速设计才需要补
#   set_input_delay/set_output_delay，见 fpga/04-timing-constraints.md。
