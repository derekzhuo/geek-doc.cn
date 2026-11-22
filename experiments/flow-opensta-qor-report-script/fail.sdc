# 违例版：同一 DUT，只把周期收紧到 0.5 ns，制造 DATA 组 setup 负 slack。
create_clock -name clk -period 0.5 [get_ports clk]
set_propagated_clock [get_clocks clk]
set_input_delay 0.30 -max -clock clk [get_ports d_in]
set_input_delay 0.15 -min -clock clk [get_ports d_in]
group_path -name CTRL -to [get_pins u_ctrl1/D]
group_path -name DATA -to [get_pins {u_data1/D u_data2/D}]
