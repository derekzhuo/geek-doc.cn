file delete -force ./v13fixed
puts "INSTALLED_PART_BEGIN xc7a35tcpg236-1"
puts "GET_PARTS_MATCH [llength [get_parts -quiet xc7a35tcpg236-1]]"
set rc [catch {create_project v13fixed ./v13fixed -part xc7a35tcpg236-1} result]
if {$rc == 0} {
  puts "INSTALLED_PART_CREATED [get_property PART [current_project]]"
  close_project
  file delete -force ./v13fixed
} else {
  puts "INSTALLED_PART_FAILED $result"
  exit 1
}
puts "INSTALLED_PART_END"
exit
