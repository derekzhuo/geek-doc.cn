file delete -force ./timing_bad
create_project timing_bad ./timing_bad -part xc7a35tcpg236-1
add_files mux_stage.v
add_files mux_chain_bad.v
add_files timing.xdc
update_compile_order -fileset sources_1

proc print_wns {tag} {
  set rc [catch {
    set tp [get_timing_paths -max_paths 1 -nworst 1 -sort_by slack]
    set wns [get_property SLACK [lindex $tp 0]]
    puts "TIMING_${tag}_WNS_VALUE $wns"
  } err]
  if {$rc != 0} {
    puts "TIMING_${tag}_WNS_QUERY_FAILED $err"
  }
}

puts "TIMING_BAD_BEGIN 64-stage external-select mux cloud between two FFs, 2ns clock"
synth_design -top mux_chain_bad
puts "TIMING_BAD_SYNTH_SUMMARY_BEGIN"
catch {report_timing_summary -delay_type max}
print_wns BAD_SYNTH
catch {report_utilization}
puts "TIMING_BAD_SYNTH_SUMMARY_END"

place_design
route_design
puts "TIMING_BAD_ROUTE_SUMMARY_BEGIN"
catch {report_timing_summary -delay_type max}
print_wns BAD_ROUTE
puts "TIMING_BAD_WORST_PATH_BEGIN"
catch {report_timing -max_paths 1 -nworst 1 -delay_type max -sort_by slack}
puts "TIMING_BAD_WORST_PATH_END"
puts "TIMING_BAD_END route_design completes with no hard error despite negative WNS"
exit
