source common.tcl
puts "CASE: probe report_check_types -max_fanout on OpenSTA 2.0.17"
report_check_types -max_fanout -violators
