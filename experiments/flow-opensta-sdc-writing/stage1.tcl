source common.tcl
source s1_clock.sdc
puts "================ STAGE 1: clock only ================"
report_checks -path_delay max -group_count 10
report_checks -path_delay min -group_count 10
