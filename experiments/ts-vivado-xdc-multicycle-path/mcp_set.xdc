create_clock -name sys_clk -period 10.000 [get_ports clk]
set_multicycle_path 2 -setup -from [get_cells stage_reg] -to [get_cells q_reg]
