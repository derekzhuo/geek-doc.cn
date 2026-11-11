read_liberty tiny.lib
read_verilog top.v
link_design top
create_clock -name clk -period 10 [get_ports clk]
create_generated_clock -name gclk -source [get_pins u_buf2/CLKX] -divide_by 2 [get_pins u_buf2/Y]
puts "generated clocks=[all_clocks]"
