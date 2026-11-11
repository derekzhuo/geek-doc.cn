source common.tcl
puts "CASE: diagnostic max_fanout limit 6, actual loads 6"
set_max_fanout 6.0 [current_design]
source fanout_report.tcl
report_max_fanout n u_drive/Y 6.0
puts "RELAXED_CHECK_DONE: no design changes"
