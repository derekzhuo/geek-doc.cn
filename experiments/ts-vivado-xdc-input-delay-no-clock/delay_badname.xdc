create_clock -name sys_clk -period 10.000 [get_ports clk]
set_input_delay -clock no_such_clk -max 5.000 [get_ports en]
