source common.tcl
puts "CASE: wrong port name clck"
source wrong_port.sdc
check_setup -verbose
report_clock_properties
report_checks -path_delay max -format full_clock_expanded -fields {slew cap input_pins nets} -digits 3
