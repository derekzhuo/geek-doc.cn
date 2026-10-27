# card 9 run B: 2-cycle multicycle path on all reg-to-reg paths
read_liberty $env(STA_LIB)
read_verilog sta_demo_net.v
link_design sta_demo
create_clock -name clk -period 10.0 [get_ports clk]
set_multicycle_path 2 -setup -from [all_registers] -to [all_registers]
set_multicycle_path 1 -hold  -from [all_registers] -to [all_registers]
report_checks -path_delay max
