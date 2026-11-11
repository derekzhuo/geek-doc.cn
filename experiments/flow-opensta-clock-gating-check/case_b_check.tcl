read_liberty teaching.lib
read_verilog top.v
link_design top
create_clock -name clk -period 2.0 [get_ports clk]
set_input_delay 0.2 -clock clk [get_ports en_in]
set_input_delay 0.2 -clock clk [get_ports d]
set_propagated_clock [all_clocks]
set_clock_gating_check -setup 0.10 -hold 0.05 [get_pins u_gate/B]
puts "#### CASE B: set_clock_gating_check -setup 0.10 -hold 0.05, gating group only"
report_checks -path_delay min_max -path_group {**clock_gating_default**}
puts "#### CASE B2: report_checks -group_count 1 (all groups, max)"
report_checks -group_count 1 -path_delay max -fields {}
