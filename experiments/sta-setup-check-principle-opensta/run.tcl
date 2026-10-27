# card 11: full setup check report (data arrival / data required line by line)
read_liberty $env(STA_LIB)
read_verilog sta_demo_net.v
link_design sta_demo
create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay  -clock clk 2.0 [get_ports {rst_n en}]
set_output_delay -clock clk 1.5 [get_ports q]
report_checks -path_delay max -format full
