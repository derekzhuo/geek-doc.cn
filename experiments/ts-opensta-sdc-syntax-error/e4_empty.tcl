source common.tcl
puts "CASE: e4_empty"
source e4_empty.sdc
check_setup -verbose
report_clock_properties
