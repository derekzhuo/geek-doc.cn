source common.tcl
puts "CASE: wrong SDF DESIGN chip_top; linked design is top"
read_sdf wrong_design.sdf
report_checks -path_delay max -format full_clock_expanded -digits 3
