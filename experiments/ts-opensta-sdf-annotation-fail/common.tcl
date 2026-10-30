read_liberty experiment.lib
read_verilog top.v
link_design top
puts "LINK_OK: linked design top"
create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 1.0 -clock clk [get_ports d]
set_output_delay 1.0 -clock clk [get_ports q]
