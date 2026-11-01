# 错误 4：对象模式不匹配，设计里没有名为 ddata 的端口
create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 1.0 -clock clk [get_ports ddata]
set_output_delay 1.0 -clock clk [get_ports q]
