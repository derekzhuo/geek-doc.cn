read_liberty teaching.lib
read_verilog top.v
link_design top
create_clock -name clk -period 2.0 [get_ports clk]
set_input_delay 0.2 -clock clk [get_ports en_in]
set_input_delay 0.2 -clock clk [get_ports d]
set_propagated_clock [all_clocks]
puts "#### CASE A: no set_clock_gating_check (inferred, 0.00 gating times)"
report_checks -path_delay min_max -path_group {**clock_gating_default**}
