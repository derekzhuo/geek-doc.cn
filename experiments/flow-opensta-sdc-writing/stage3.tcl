source common.tcl
source s1_clock.sdc
source s2_io.sdc
source s3_exc.sdc
puts "================ STAGE 3: clock + IO + exceptions ================"
report_checks -path_delay max -group_count 10
report_checks -path_delay min -group_count 10
