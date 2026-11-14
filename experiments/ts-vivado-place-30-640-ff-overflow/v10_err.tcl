file delete -force ./v10bad
create_project v10bad ./v10bad -part xc7a35tcpg236-1
add_files v10_overflow_bad.v
update_compile_order -fileset sources_1
puts "V10_BAD_BEGIN synth 60000 FF design on xc7a35t"
synth_design -top v10_overflow_bad
puts "V10_BAD_POST_SYNTH [get_property STATISTICS.FFs [get_runs synth_1]]"
set rc [catch {place_design} result]
if {$rc != 0} {
  puts "V10_BAD_PLACE_FAILED"
  puts "V10_BAD_PLACE_ERROR $result"
} else {
  puts "V10_BAD_UNEXPECTED_PLACE_OK"
}
puts "V10_BAD_END"
exit
