# 反例：定义了 ff 角却忘了给它 read_liberty（静默回退到别的角）
define_corners ss tt ff
read_liberty -corner ss ss.lib
read_liberty -corner tt tt.lib
read_verilog top.v
link_design top
create_clock -name clk -period 1.2 [get_ports clk]
report_checks -corner ff -path_delay max -digits 3
