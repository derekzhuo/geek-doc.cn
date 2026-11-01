# 场景 4：同作用域重复设置，后一条覆盖前一条（不是累加）
read_liberty experiment.lib
read_verilog top.v
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
set_clock_uncertainty -setup 0.5 [get_clocks clk]
set_clock_uncertainty -setup 0.8 [get_clocks clk]
report_checks -path_delay max
