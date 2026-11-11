read_liberty tiny.lib
read_verilog top.v
link_design top
create_clock -name clk -period 10 [get_ports clk]
create_generated_clock -name gclk -source [get_ports clk] -divide_by 2 [get_pins u_buf2/Y]
foreach c [all_clocks] { puts "clock=[get_name $c] generated=[$c is_generated] period=[$c period]" }
report_clock_properties [all_clocks]
