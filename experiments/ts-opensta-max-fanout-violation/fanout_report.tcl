proc report_max_fanout {net_name driver_name limit} {
  set net [get_nets $net_name]
  set input_pins [get_pins -of_objects $net -filter "direction == input"]
  set output_ports [get_ports -of_objects $net -filter "direction == output"]
  set fanout [expr {[llength $input_pins] + [llength $output_ports]}]
  set slack [expr {$limit - $fanout}]
  puts "MAX_FANOUT_CHECK net=$net_name driver=$driver_name limit=$limit fanout=$fanout slack=$slack"
  if {$fanout > $limit} {
    puts "MAX_FANOUT_VIOLATION net=$net_name loads=$fanout limit=$limit"
  } else {
    puts "MAX_FANOUT_OK net=$net_name loads=$fanout limit=$limit"
  }
}
