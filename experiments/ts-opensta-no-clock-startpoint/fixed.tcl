source common.tcl
puts "CASE: fixed create_clock on input port clk"
create_clock -name clk -period 1.0 [get_ports clk]
set_input_delay  -clock clk 0.2 [get_ports d]
set_output_delay -clock clk 0.0 [get_ports q]
puts "ALL_CLOCKS_COUNT=[llength [all_clocks]]"
report_clock_properties
puts "CHECK_SETUP_BEGIN"
check_setup
puts "CHECK_SETUP_END"
puts "REPORT_BEGIN"
report_checks -fields {slew input_pins} -digits 3
puts "REPORT_END"
