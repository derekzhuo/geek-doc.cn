create_clock -name dest_clk -period 10.000 [get_ports dest_clk]
create_clock -name src_clk -period 7.000 [get_ports src_clk]
set_clock_groups -asynchronous -group [get_clocks src_clk] -group [get_clocks dest_clk]
