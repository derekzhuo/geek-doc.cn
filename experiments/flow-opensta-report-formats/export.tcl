# 读入最小教学库与四条路径网表，周期 0.8ns 故意制造 3 条 setup 违例
read_liberty teaching.lib
read_verilog top.v
link_design top
create_clock -name clk -period 0.8 [get_ports clk]
set_input_delay  -clock clk 0.0 [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock clk 0.0 [all_outputs]

# 用 tcl 重定向把不同 -format 分别落盘
report_checks -path_delay max -format short         -group_count 30 > reports/short.rpt
report_checks -path_delay max -format end           -group_count 30 > reports/end.rpt
report_checks -path_delay max -format full          -group_count 30 > reports/full.rpt
report_checks -path_delay max -format full_clock    -group_count 30 > reports/full_clock.rpt
report_checks -path_delay max -format summary       -group_count 30 > reports/summary.rpt
# 原生命令直接筛 slack <= 0 的路径，不需要 grep
report_checks -path_delay max -format end -slack_max 0.0 -group_count 30 > reports/violators.rpt
puts "EXPORT_DONE"
