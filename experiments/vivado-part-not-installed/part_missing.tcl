file delete -force ./v13missing
puts "MISSING_PART_BEGIN xc6slx9-tqg144-2"
puts "GET_PARTS_MATCH [llength [get_parts -quiet xc6slx9-tqg144-2]]"
set rc [catch {create_project v13missing ./v13missing -part xc6slx9-tqg144-2} result]
if {$rc == 0} {
  puts "UNEXPECTED_PROJECT_CREATED"
  close_project
  file delete -force ./v13missing
  exit 1
} else {
  puts "MISSING_PART_RESULT FAILED"
  puts "MISSING_PART_ERROR $result"
}
puts "MISSING_PART_END"
exit
