puts "================ EXCEPTIONS ================"
if {[llength [info commands report_exceptions]]} {
  report_exceptions
} else {
  puts "NOTE: report_exceptions is unavailable in OpenSTA 2.0.17; use path-specific report_checks below."
}
puts "================ DATA SETUP ================"
report_checks -path_delay max -from [get_cells u_a] -to [get_cells u_b]
puts "================ DATA HOLD ================"
report_checks -path_delay min -from [get_cells u_a] -to [get_cells u_b]
puts "================ CONFIG SETUP ================"
report_checks -path_delay max -from [get_cells u_cfg] -to [get_cells u_shadow]
puts "================ CONFIG HOLD ================"
report_checks -path_delay min -from [get_cells u_cfg] -to [get_cells u_shadow]
