# 阶段 2：在时钟基础上补 IO 边界约束。
# set_input_delay：外部器件在 clk 沿之后 1.0ns 才把数据放到端口，
# 即留给芯片内部的建立时间预算要减掉这 1.0ns。
set_input_delay  -clock clk 1.0 [get_ports {d_in en_in}]
# set_output_delay：下游器件要求芯片输出在下次 clk 沿之前 0.5ns 稳定。
set_output_delay -clock clk  0.5 [get_ports q_out]
set_output_delay -clock clk2 0.5 [get_ports q2]
