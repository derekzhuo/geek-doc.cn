# 修复：先 create_clock 再用正确时钟名设 uncertainty，setup/hold 分开
read_liberty experiment.lib
read_verilog top.v
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
set_clock_uncertainty -setup 0.5 [get_clocks clk]
set_clock_uncertainty -hold  0.2 [get_clocks clk]
puts "GET_CLOCKS_RESULT=[get_clocks clk]"
report_clock_properties
if {[catch {report_clock_uncertainty} err]} {
  puts "NO_SUCH_CMD: report_clock_uncertainty -> $err"
}
puts "=== setup (path_delay max) ==="
report_checks -path_delay max
puts "=== hold (path_delay min) ==="
report_checks -path_delay min
