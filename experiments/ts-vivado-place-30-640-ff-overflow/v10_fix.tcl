file delete -force ./v10fixed
create_project v10fixed ./v10fixed -part xc7a35tcpg236-1
add_files v10_overflow_fixed.v
update_compile_order -fileset sources_1
puts "V10_FIX_BEGIN synth 2000 FF design on xc7a35t"
synth_design -top v10_overflow_fixed
set rc [catch {place_design} result]
if {$rc != 0} {
  puts "V10_FIX_UNEXPECTED_PLACE_FAIL $result"
  exit 1
}
puts "V10_FIX_PLACE_OK"
report_utilization
puts "V10_FIX_END"
exit
