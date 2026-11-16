create_clock -name sys_clk -period 10.000 [get_ports clk]
set_false_path -from [get_cells stage_reg] -to [get_cells q_reg]
