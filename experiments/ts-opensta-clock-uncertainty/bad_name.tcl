# 场景 1：时钟名拼错，get_clocks 解析为空集合
read_liberty experiment.lib
read_verilog top.v
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
set_clock_uncertainty 0.5 [get_clocks clkc]
puts "GET_CLOCKS_RESULT=[get_clocks clkc]"
report_checks -path_delay max
