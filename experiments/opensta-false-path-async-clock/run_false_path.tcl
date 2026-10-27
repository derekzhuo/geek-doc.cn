# card 10 run A: two async clocks + set_false_path on the crossing
read_liberty $env(STA_LIB)
read_verilog sta_async_net.v
link_design sta_async
create_clock -name clk_a -period 10.0 [get_ports clk_a]
create_clock -name clk_b -period  7.0 [get_ports clk_b]
set_false_path -from [get_clocks clk_a] -to [get_clocks clk_b]
report_checks
