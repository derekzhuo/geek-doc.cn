# card 7: create_clock + report_checks
read_liberty $env(STA_LIB)
read_verilog sta_demo_net.v
link_design sta_demo
create_clock -name clk -period 10.0 [get_ports clk]
set_propagated_clock [all_clocks]
report_checks
