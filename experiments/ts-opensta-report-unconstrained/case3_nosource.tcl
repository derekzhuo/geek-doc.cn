# 根因 3a：sta 只跑了这个 tcl，SDC 文件根本没有被 source
read_liberty good.lib
read_verilog top.v
link_design top
puts "LINK_OK"
puts "CASE 3a: constraints.sdc never sourced"
source diag.tcl
clock_chain
check_setup -verbose
report_clock_properties
report_checks -path_delay max -digits 3
