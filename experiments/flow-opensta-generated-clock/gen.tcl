source common.tcl
source gen.sdc

puts "========== CLOCK PROPERTIES =========="
report_clock_properties [all_clocks]
puts "========== CHECK_SETUP -verbose =========="
check_setup -verbose
puts "========== REPORT_CHECKS SETUP (max) =========="
report_checks -path_delay max -digits 4
puts "========== REPORT_CHECKS HOLD (min) =========="
report_checks -path_delay min -digits 4
puts "========== REPORT_CLOCK_SKEW =========="
report_clock_skew -setup -digits 4
puts "========== GEN STAGE DONE =========="
