# case B: clock defined as clck, referenced as clk and top/clk
create_clock -name clck -period 10.0 [get_ports clk]
set_input_delay  1.0 -clock clk      [get_ports d]
set_input_delay  1.0 -clock top/clk   [get_ports d]
set_output_delay 1.0 -clock clk       [get_ports q]
