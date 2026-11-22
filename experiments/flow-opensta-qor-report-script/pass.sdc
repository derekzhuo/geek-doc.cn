# 满足版：周期 4.0 ns，全部端点 slack 为正。
create_clock -name clk -period 4.0 [get_ports clk]
set_propagated_clock [get_clocks clk]
# 输入端口 d_in 带片外发射延迟，进入默认 clk 组；输出端口不设约束（见 qor.tcl 的无约束审计）。
set_input_delay 0.30 -max -clock clk [get_ports d_in]
set_input_delay 0.15 -min -clock clk [get_ports d_in]
# 按功能块建路径组：CTRL 控制通路，DATA 数据通路。
group_path -name CTRL -to [get_pins u_ctrl1/D]
group_path -name DATA -to [get_pins {u_data1/D u_data2/D}]
