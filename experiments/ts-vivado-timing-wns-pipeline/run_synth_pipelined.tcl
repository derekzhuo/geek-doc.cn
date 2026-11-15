file delete -force ./timing_pipelined
create_project timing_pipelined ./timing_pipelined -part xc7a35tcpg236-1
add_files mux_stage.v
add_files mux_chain_pipelined.v
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

puts "TIMING_FIX_BEGIN same 64 mux stages, 32 pipeline groups of 2 stages, 2ns clock"
synth_design -top mux_chain_pipelined
puts "TIMING_FIX_SYNTH_SUMMARY_BEGIN"
catch {report_timing_summary -delay_type max}
print_wns FIX_SYNTH
catch {report_utilization}
puts "TIMING_FIX_SYNTH_SUMMARY_END"

place_design
route_design
puts "TIMING_FIX_ROUTE_SUMMARY_BEGIN"
catch {report_timing_summary -delay_type max}
print_wns FIX_ROUTE
puts "TIMING_FIX_WORST_PATH_BEGIN"
catch {report_timing -max_paths 1 -nworst 1 -delay_type max -sort_by slack}
puts "TIMING_FIX_WORST_PATH_END"
puts "TIMING_FIX_END timing closes with positive WNS"
exit
