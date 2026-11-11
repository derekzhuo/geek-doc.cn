# case A: create_clock missing entirely
set_input_delay 1.0 -clock clk [get_ports d]
set_output_delay 1.0 -clock clk [get_ports q]
