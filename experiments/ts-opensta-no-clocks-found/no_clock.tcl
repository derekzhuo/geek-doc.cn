source common.tcl
puts "CASE: no create_clock"
check_setup -verbose
report_clock_properties
report_checks -path_delay max -format full_clock_expanded -fields {slew cap input_pins nets} -digits 3
