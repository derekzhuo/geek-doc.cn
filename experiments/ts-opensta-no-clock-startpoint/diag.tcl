source common.tcl
puts "DIAG: object inventory before any create_clock"
puts "INPUT_PORTS_BEGIN"
foreach p [all_inputs] { puts "  port [get_property $p name]" }
puts "INPUT_PORTS_END"
puts "CLOCK_PINS_BEGIN"
foreach p [get_pins u_a/C] { puts "  pin [get_property $p full_name]" }
foreach p [get_pins u_b/C] { puts "  pin [get_property $p full_name]" }
puts "CLOCK_PINS_END"
puts "ALL_CLOCKS_COUNT=[llength [all_clocks]]"
puts "CHECK_SETUP_BEFORE_BEGIN"
check_setup
puts "CHECK_SETUP_BEFORE_END"
create_clock -name clk -period 1.0 [get_ports clk]
puts "DIAG: after create_clock on port clk"
foreach c [all_clocks] {
  puts "CLOCK=[get_property $c name] PERIOD=[get_property $c period]"
  foreach s [get_property $c sources] { puts "  SOURCE=[get_property $s full_name]" }
}
puts "CHECK_SETUP_AFTER_BEGIN"
check_setup
puts "CHECK_SETUP_AFTER_END"
