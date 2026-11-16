file delete -force ./place_fixed
create_project place_fixed ./place_fixed -part xc7a35tcpg236-1
add_files ff_overflow_fixed.v
update_compile_order -fileset sources_1
puts "PLACE_FF_FIX_BEGIN synth 2000 FF design on xc7a35t"
synth_design -top ff_overflow_fixed
set rc [catch {place_design} result]
if {$rc != 0} {
  puts "PLACE_FF_FIX_UNEXPECTED_PLACE_FAIL $result"
  exit 1
}
puts "PLACE_FF_FIX_PLACE_OK"
report_utilization
puts "PLACE_FF_FIX_END"
exit
