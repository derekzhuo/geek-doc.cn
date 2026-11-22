# 版本一：只约束主时钟，不声明分频输出上的生成时钟。
# u_cap 的时钟引脚经 gclk 追溯到 u_div/Q，那里没有任何时钟对象，
# 用来暴露「未约束生成时钟域」在报告中的真实表现。
create_clock -name clk -period 4.0 [get_ports clk]
set_propagated_clock [get_clocks clk]
set_input_delay 0.30 -max -clock clk [get_ports d_in]
set_input_delay 0.15 -min -clock clk [get_ports d_in]
