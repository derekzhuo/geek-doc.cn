# 场景 3b：不带 -setup/-hold 时，同一值同时作用于 setup 与 hold
read_liberty experiment.lib
read_verilog top.v
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
set_clock_uncertainty 0.5 [get_clocks clk]
puts "=== setup (path_delay max) ==="
report_checks -path_delay max
puts "=== hold (path_delay min) ==="
report_checks -path_delay min
