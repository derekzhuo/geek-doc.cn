# 根因 1：时钟建到了错误的网络（数据缓冲的内部脚），clk 端口上没有时钟
read_liberty good.lib
read_verilog top.v
link_design top
puts "LINK_OK"
puts "CASE 1: create_clock attached to wrong net (u_buf/A instead of port clk)"
create_clock -name clk -period 10.0 [get_pins u_buf/A]
source diag.tcl
clock_chain
check_setup -verbose
report_clock_properties
report_checks -path_delay max -digits 3
