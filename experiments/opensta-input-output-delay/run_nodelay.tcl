# card 8 run A: clock only, NO input/output delay constraints
read_liberty $env(STA_LIB)
read_verilog sta_demo_net.v
link_design sta_demo
create_clock -name clk -period 10.0 [get_ports clk]
report_checks
