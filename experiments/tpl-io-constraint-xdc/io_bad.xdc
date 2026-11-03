# 错误版：端口名手滑写成 din0（实际端口是 din[*]），
# get_ports 匹配不到任何对象，read_sdc 在本行中止，
# 后续 output delay 全部缺失，输出端口路径变成 unconstrained。
create_clock -name clk -period 10.0 [get_ports clk]
create_clock -name vclk -period 10.0
set_input_delay -clock clk -min 0.5 [get_ports din0]
set_input_delay -clock clk -max 1.2 [get_ports din0]
set_output_delay -clock clk -min 0.4 [get_ports {dout[*]}]
set_output_delay -clock clk -max 1.0 [get_ports {dout[*]}]
set_output_delay -clock vclk -min 0.4 [get_ports led]
set_output_delay -clock vclk -max 1.0 [get_ports led]
set_output_delay -clock clk -min 0.4 [get_ports combo]
set_output_delay -clock clk -max 1.0 [get_ports combo]
set_clock_uncertainty 0.2 [get_clocks clk]
set_input_transition 0.3 [all_inputs]
set_load 0.05 [all_outputs]
