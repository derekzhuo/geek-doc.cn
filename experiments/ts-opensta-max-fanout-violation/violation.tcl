source common.tcl
puts "CASE: max_fanout limit 4, actual loads 6"
set_max_fanout 4.0 [current_design]
source fanout_report.tcl
report_max_fanout n u_drive/Y 4.0
