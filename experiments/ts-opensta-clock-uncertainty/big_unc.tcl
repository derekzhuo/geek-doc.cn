# 场景 5：uncertainty 值过大，把本应宽松 9.7ns 的路径打成 VIOLATED
read_liberty experiment.lib
read_verilog top.v
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
set_clock_uncertainty 9.9 [get_clocks clk]
report_checks -path_delay max
