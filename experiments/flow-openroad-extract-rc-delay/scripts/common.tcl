proc read_physical {def_file} {
  read_liberty fixtures/teaching.lib
  read_lef fixtures/tech.lef
  read_lef fixtures/stdcell.lef
  read_def $def_file
  source fixtures/io.sdc
}

proc snap {tag} {
  puts "SNAP stage=$tag setup_wns=[format %.6f [sta::worst_slack -max]] setup_tns=[format %.6f [sta::total_negative_slack -max]]"
  set report_file "results/${tag}_path.rpt"
  report_checks -from d_in -to z_out -path_delay max -format full \
    -fields {capacitance slew fanout} -digits 6 -no_line_splits > $report_file
  set json_file "results/${tag}_path.json"
  report_checks -from d_in -to z_out -path_delay max -format json \
    -digits 9 > $json_file
  set fp [open $report_file r]
  set data [read $fp]
  close $fp
  foreach line [split $data "\n"] {
    if {[regexp {data arrival time} $line]} {
      puts "ARRIVAL stage=$tag $line"
    }
  }
}
