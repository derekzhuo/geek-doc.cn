# 场景 2：先设 uncertainty 后 create_clock，对象集合当时为空
read_liberty experiment.lib
read_verilog top.v
link_design top
set_clock_uncertainty 0.5 [get_clocks clk]
create_clock -name clk -period 10.0 [get_ports clk]
report_checks -path_delay max
