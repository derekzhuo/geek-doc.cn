source common.tcl
source s1_clock.sdc
source s2_io.sdc
puts "================ STAGE 2: clock + IO delay ================"
report_checks -path_delay max -group_count 10
report_checks -path_delay min -group_count 10
