# 场景 3：-rise/-fall 误用报错 + -setup/-hold 作用域分别计入
read_liberty experiment.lib
read_verilog top.v
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
# 下面两行在 2.0.17 下直接报错：单时钟 uncertainty 不允许 -rise/-fall
set_clock_uncertainty -rise -setup 0.5 [get_clocks clk]
set_clock_uncertainty -fall -setup 0.8 [get_clocks clk]
# 正确写法：setup 与 hold 分开设
set_clock_uncertainty -setup 0.5 [get_clocks clk]
set_clock_uncertainty -hold  0.3 [get_clocks clk]
puts "=== setup (path_delay max) ==="
report_checks -path_delay max
puts "=== hold (path_delay min) ==="
report_checks -path_delay min
