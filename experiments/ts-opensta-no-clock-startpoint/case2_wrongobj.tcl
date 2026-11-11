source common.tcl
puts "CASE: 2 create_clock on internal pin u_a/C instead of input port clk"
create_clock -name clk -period 1.0 [get_pins u_a/C]
foreach c [all_clocks] {
  puts "CLOCK=[get_property $c name]"
  foreach s [get_property $c sources] { puts "  SOURCE=[get_property $s full_name]" }
}
puts "CHECK_SETUP_BEGIN"
check_setup
puts "CHECK_SETUP_END"
puts "REPORT_BEGIN"
report_checks -fields {slew input_pins} -digits 3
puts "REPORT_END"
puts "REPORT_UNC_BEGIN"
report_checks -unconstrained -fields {slew input_pins} -digits 3
puts "REPORT_UNC_END"
