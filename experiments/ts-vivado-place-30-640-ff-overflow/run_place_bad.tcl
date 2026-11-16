file delete -force ./place_bad
create_project place_bad ./place_bad -part xc7a35tcpg236-1
add_files ff_overflow_bad.v
update_compile_order -fileset sources_1
puts "PLACE_FF_OVERFLOW_BAD_BEGIN synth 60000 FF design on xc7a35t"
synth_design -top ff_overflow_bad
puts "PLACE_FF_OVERFLOW_BAD_POST_SYNTH [get_property STATISTICS.FFs [get_runs synth_1]]"
set rc [catch {place_design} result]
if {$rc != 0} {
  puts "PLACE_FF_OVERFLOW_BAD_PLACE_FAILED"
  puts "PLACE_FF_OVERFLOW_BAD_PLACE_ERROR $result"
} else {
  puts "PLACE_FF_OVERFLOW_BAD_UNEXPECTED_PLACE_OK"
}
puts "PLACE_FF_OVERFLOW_BAD_END"
exit
