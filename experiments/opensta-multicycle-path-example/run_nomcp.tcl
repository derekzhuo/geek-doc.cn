# card 9 run A: single-cycle check, no multicycle exception
read_liberty $env(STA_LIB)
read_verilog sta_demo_net.v
link_design sta_demo
create_clock -name clk -period 10.0 [get_ports clk]
report_checks -path_delay max
