create_clock -name clk -period 10 [get_ports clk]
set_input_delay 0.5 -clock clk [get_ports d]
set_output_delay 0.3 -clock clk [get_ports q]
