# 根因 3b：SDC 在 link 之前 source，三条约束全部落空
puts "CASE 3b: source constraints.sdc BEFORE read_liberty/read_verilog"
source constraints.sdc
read_liberty good.lib
read_verilog top.v
link_design top
puts "LINK_OK"
source diag.tcl
clock_chain
check_setup -verbose
report_clock_properties
report_checks -path_delay max -digits 3
