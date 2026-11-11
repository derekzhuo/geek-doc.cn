source common.tcl
source s1_clock.sdc
source s2_io.sdc
source s3_exc.sdc
source s4_mcp_hold.sdc
puts "================ STAGE 4: add multicycle hold 1 ================"
report_checks -path_delay max -group_count 10
report_checks -path_delay min -group_count 10
