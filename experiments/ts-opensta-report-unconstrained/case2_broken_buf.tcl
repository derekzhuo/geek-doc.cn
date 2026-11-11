# 根因 2：clk 端口时钟建对了，但 CLK_BUF 在库里缺时序弧，时钟传不到寄存器
read_liberty broken.lib
read_verilog top.v
link_design top
puts "LINK_OK"
puts "CASE 2: clock on clk port but CLK_BUF has no timing arc (broken.lib)"
source constraints.sdc
source diag.tcl
clock_chain
check_setup -verbose
report_clock_properties
report_checks -path_delay max -digits 3
