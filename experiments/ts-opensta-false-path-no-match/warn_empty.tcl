source common.tcl
puts "CASE: regex metachar without -regexp"
puts "MATCH_COUNT=[llength [get_pins -quiet {u_b./D}]]"
source warn_empty.sdc
report_checks -fields {slew input_pins} -digits 3
