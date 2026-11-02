# 多角分析：一次读入 ss/tt/ff 三个角的库，逐角出 setup/hold 报告
define_corners ss tt ff
read_liberty -corner ss ss.lib
read_liberty -corner tt tt.lib
read_liberty -corner ff ff.lib
read_verilog top.v
link_design top
create_clock -name clk -period 1.2 [get_ports clk]
foreach corner {ss tt ff} {
  puts "########## CORNER $corner : setup (path_delay max) ##########"
  report_checks -corner $corner -path_delay max -digits 3
  puts "########## CORNER $corner : hold (path_delay min) ##########"
  report_checks -corner $corner -path_delay min -digits 3
}
puts "########## ALL CORNERS : report_checks 不带 -corner ##########"
report_checks -path_delay max -digits 3
