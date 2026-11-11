# 错误 5：SDC 数值不带单位，10ns 无法解析为浮点数
create_clock -name clk -period 10ns [get_ports clk]
