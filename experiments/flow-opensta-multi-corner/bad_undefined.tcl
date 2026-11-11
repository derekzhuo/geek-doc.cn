# 反例：report_checks 指定一个从未 define 的角点名
define_corners ss tt ff
read_liberty -corner ss ss.lib
read_liberty -corner tt tt.lib
read_liberty -corner ff ff.lib
read_verilog top.v
link_design top
create_clock -name clk -period 1.2 [get_ports clk]
report_checks -corner ff_x -path_delay max
