source common.tcl
puts "CASE: 1 no create_clock at all"
puts "ALL_CLOCKS_COUNT=[llength [all_clocks]]"
puts "CHECK_SETUP_BEGIN"
check_setup
puts "CHECK_SETUP_END"
puts "REPORT_CONSTRAINED_BEGIN"
report_checks -fields {slew input_pins} -digits 3
puts "REPORT_CONSTRAINED_END"
puts "REPORT_UNCONSTRAINED_BEGIN"
report_checks -unconstrained -fields {slew input_pins} -digits 3
puts "REPORT_UNCONSTRAINED_END"
