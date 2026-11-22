source common.tcl
source nogen.sdc

puts "========== CLOCK PROPERTIES =========="
report_clock_properties [all_clocks]
puts "========== CHECK_SETUP -verbose =========="
check_setup -verbose
puts "========== REPORT_CHECKS SETUP (max) =========="
report_checks -path_delay max -digits 4
puts "========== REPORT_CHECKS HOLD (min) =========="
report_checks -path_delay min -digits 4
puts "========== REPORT_CHECKS -unconstrained =========="
report_checks -unconstrained -digits 4
puts "========== NOGEN STAGE DONE =========="
