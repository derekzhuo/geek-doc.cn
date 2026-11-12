set candidates [list \
  xc6slx9-tqg144-2 \
  xcvc1902-vsva2197-2MP-S \
  xc7a999tcsg324-1 \
]
set index 0
foreach part $candidates {
  incr index
  puts "PROBE_PART_BEGIN $part"
  puts "GET_PARTS_MATCH [llength [get_parts -quiet $part]]"
  set rc [catch {create_project v13probe$index ./v13probe$index -part $part} result]
  if {$rc == 0} {
    puts "PROBE_RESULT CREATED"
    close_project
    file delete -force ./v13probe$index
  } else {
    puts "PROBE_RESULT FAILED"
    puts "PROBE_ERROR $result"
  }
  puts "PROBE_PART_END $part"
}
puts "FIXED_PART_BEGIN xc7a35tcpg236-1"
set rc [catch {create_project v13fixed ./v13fixed -part xc7a35tcpg236-1} result]
if {$rc == 0} {
  puts "FIXED_PART_CREATED [get_property PART [current_project]]"
  close_project
  file delete -force ./v13fixed
} else {
  puts "FIXED_PART_FAILED $result"
  exit 1
}
puts "FIXED_PART_END"
exit
