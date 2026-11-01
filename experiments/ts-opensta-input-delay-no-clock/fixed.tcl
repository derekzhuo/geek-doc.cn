source common.tcl
puts "CASE: fixed"
source fixed.sdc
check_setup -verbose
report_clock_properties
puts "--- report_checks: input path d -> u_stage/D ---"
report_checks -from [get_ports d] -to [get_pins u_stage/D] -path_delay max -format full_clock_expanded -fields {slew cap input_pins nets} -digits 3
puts "--- report_checks: default worst path ---"
report_checks -path_delay max -format full_clock_expanded -fields {slew cap input_pins nets} -digits 3
