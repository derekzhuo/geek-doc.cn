source common.tcl
puts "CASE: 3 clock named sys_clk but SDC later asks for clock clk"
create_clock -name sys_clk -period 1.0 [get_ports clk]
puts "ALL_CLOCKS=[all_clocks]"
puts "GET_CLOCKS_BEGIN"
get_clocks clk
puts "GET_CLOCKS_END"
set_input_delay -clock clk 0.2 [all_inputs]
puts "REPORT_BEGIN"
report_checks -fields {slew input_pins} -digits 3
puts "REPORT_END"
