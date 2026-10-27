# card 10 run B: two async clocks + set_clock_groups -asynchronous
read_liberty $env(STA_LIB)
read_verilog sta_async_net.v
link_design sta_async
create_clock -name clk_a -period 10.0 [get_ports clk_a]
create_clock -name clk_b -period  7.0 [get_ports clk_b]
set_clock_groups -asynchronous -group [get_clocks clk_a] -group [get_clocks clk_b]
report_checks
