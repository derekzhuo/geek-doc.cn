source common.tcl
puts "CASE: fixed hierarchical pin name"
puts "MATCH_COUNT=[llength [get_pins -quiet u_b/D]]"
source fixed.sdc
puts "REPORT_BEGIN"
report_checks -fields {slew input_pins} -digits 3
puts "REPORT_END"
