puts "INSTALLED_PARTS_BEGIN"
foreach part [get_parts] {
  puts $part
}
puts "INSTALLED_PARTS_END"
exit
