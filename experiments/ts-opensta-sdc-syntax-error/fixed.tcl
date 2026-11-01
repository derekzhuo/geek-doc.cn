source common.tcl
puts "CASE: fixed"
source fixed.sdc
check_setup -verbose
report_clock_properties
report_checks -path_delay max -format full_clock_expanded -digits 3
