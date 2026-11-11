# 修复：库含完整时序弧 + SDC 在 link 之后 source 到真实 clk 端口
read_liberty good.lib
read_verilog top.v
link_design top
puts "LINK_OK"
puts "FIXED: good.lib, source constraints.sdc after link, clock on port clk"
source constraints.sdc
source diag.tcl
clock_chain
check_setup -verbose
report_clock_properties
report_checks -path_delay max -digits 3
