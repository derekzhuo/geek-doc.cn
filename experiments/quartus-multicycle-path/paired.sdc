create_clock -name sys_clk -period 20.000 [get_ports clk]
derive_clock_uncertainty
set_multicycle_path 2 -setup -from [get_cells stage_reg] -to [get_cells q~reg0]
set_multicycle_path 1 -hold -end -from [get_cells stage_reg] -to [get_cells q~reg0]
