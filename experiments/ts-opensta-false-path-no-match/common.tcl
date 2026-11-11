read_liberty experiment.lib
read_verilog top.v
link_design top
create_clock -name clk -period 0.4 [get_ports clk]
puts "LINK_OK: 0.4ns clock created on port clk"
