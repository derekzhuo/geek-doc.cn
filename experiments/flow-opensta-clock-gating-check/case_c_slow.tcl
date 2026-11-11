read_liberty teaching.lib
read_verilog top_slow.v
link_design top
create_clock -name clk -period 2.0 [get_ports clk]
set_input_delay 0.2 -clock clk [get_ports en_in]
set_input_delay 0.2 -clock clk [get_ports d]
set_propagated_clock [all_clocks]
set_clock_gating_check -setup 0.10 -hold 0.05 [get_pins u_gate/B]
puts "#### CASE C: long EN path (2x BUF_D1 1.60ns), gating group min_max"
report_checks -path_delay min_max -path_group {**clock_gating_default**}
puts "#### CASE C2: same object with -low (active-low select), max"
set_clock_gating_check -setup 0.10 -hold 0.05 -low [get_pins u_gate/B]
report_checks -path_delay max -path_group {**clock_gating_default**} -fields {}
