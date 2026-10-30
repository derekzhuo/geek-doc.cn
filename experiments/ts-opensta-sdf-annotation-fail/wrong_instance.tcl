source common.tcl
puts "CASE: wrong instance u_buffer; netlist has u_buf"
read_sdf wrong_instance.sdf
report_checks -path_delay max -format full_clock_expanded -digits 3
