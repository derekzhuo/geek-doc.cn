source common.tcl
puts "CASE: fixed DESIGN top and INSTANCE u_buf"
read_sdf fixed.sdf
report_checks -path_delay max -format full_clock_expanded -digits 3
