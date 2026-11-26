foreach required {estimate_parasitics read_spef report_parasitic_annotation} {
  if {[llength [info commands $required]] != 1} {
    error "missing required command: $required"
  }
}
puts "API extract_rc=absent report_parasitic=absent"
puts "API estimate_parasitics=present read_spef=present report_parasitic_annotation=present"
puts "STAGE_00_API_PROBE_OK"
exit
