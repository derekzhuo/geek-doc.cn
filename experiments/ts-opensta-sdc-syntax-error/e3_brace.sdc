# 错误 3：花括号不配对，{d q} 少了右花括号
create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 1.0 -clock clk [get_ports {d q]
