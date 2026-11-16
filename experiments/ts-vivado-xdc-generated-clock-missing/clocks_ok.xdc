create_clock -name sys_clk -period 10.000 [get_ports clk]
create_generated_clock -name clk_div -source [get_ports clk] -divide_by 2 [get_pins clk_div_reg/Q]
