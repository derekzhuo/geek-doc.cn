# extract_sta_summary.tcl
# OpenSTA timing summary extractor (verified on OpenSTA 2.0.17).
# Source this file AFTER read_liberty/read_verilog/link_design and the SDC.
#
# Parameters (set before sourcing this file, or edit the defaults):
#   sta_path_delay  max = setup check, min = hold check (default: max)
#   sta_max_paths   paths collected per path group            (default: 20)
#   sta_fail_slack WNS below this value marks STA_VIOLATED    (default: 0.0)
#   sta_csv         1 = also emit one CSV row per path        (default: 0)

if {![info exists sta_path_delay]} { set sta_path_delay "max" }
if {![info exists sta_max_paths]}  { set sta_max_paths 20 }
if {![info exists sta_fail_slack]} { set sta_fail_slack 0.0 }
if {![info exists sta_csv]}        { set sta_csv 0 }

# Map the find_timing_paths keyword to a human-readable check name.
proc sta_check_name {path_delay} {
  switch -glob -- $path_delay {
    "max*" { return "setup" }
    "min*" { return "hold" }
    default { error "sta_path_delay must be max or min, got \"$path_delay\"" }
  }
}

# Collect the worst paths of one path group. Returns an empty list when the
# design has no constrained timing path at all (for example, no clock).
proc sta_collect_paths {path_delay max_paths} {
  if {[current_design] == "null"} {
    error "no linked design; run read_liberty/read_verilog/link_design first"
  }
  if {[llength [all_clocks]] == 0} {
    return -code 10 "NO_CLOCKS"
  }
  set paths [find_timing_paths -unique_paths_to_endpoint \
    -group_count $max_paths -path_delay $path_delay -sort_by_slack]
  # find_timing_paths may embed empty elements; drop them before iterating.
  return [lsearch -all -inline -not -exact $paths {}]
}

# Fold a path list into WNS, TNS, violating-path count and total path count.
proc sta_summarize {paths} {
  set wns ""
  set tns 0.0
  set violating 0
  foreach path $paths {
    set slack [get_property $path slack]
    if {$wns eq "" || $slack < $wns} {
      set wns $slack
    }
    if {$slack < 0.0} {
      set tns [expr {$tns + $slack}]
      incr violating
    }
  }
  return [list $wns $tns $violating [llength $paths]]
}

proc sta_print_summary {check_name paths summary fail_slack csv} {
  lassign $summary wns tns violating total
  puts "------------------------------------------------------------"
  puts "STA check      : $check_name"
  puts "Paths collected: $total"
  if {$total == 0} {
    puts "WNS/TNS        : n/a (no constrained timing path)"
    puts "STA_STATUS check=$check_name status=NO_CLOCKS wns=NA tns=NA violating_paths=0 total=0"
    return
  }
  puts "WNS            : [format "%.3f" $wns]"
  puts "TNS            : [format "%.3f" $tns]"
  puts "Violating paths: $violating (slack < 0)"
  if {$wns < $fail_slack} {
    set status "VIOLATED"
  } else {
    set status "MET"
  }
  puts "STA_STATUS check=$check_name status=$status wns=[format "%.3f" $wns] tns=[format "%.3f" $tns] violating_paths=$violating total=$total"
  if {$csv} {
    puts "STA_PATH_CSV,check,startpoint,endpoint,slack"
    foreach path $paths {
      set startpin [get_property $path startpoint]
      set endpin [get_property $path endpoint]
      set slack [get_property $path slack]
      puts [format "STA_PATH_CSV,%s,%s,%s,%.3f" $check_name \
        [get_property $startpin full_name] \
        [get_property $endpin full_name] $slack]
    }
  }
}

# ---- main ----
set check_name [sta_check_name $sta_path_delay]
if {[catch {sta_collect_paths $sta_path_delay $sta_max_paths} paths err_opts]} {
  if {[dict get $err_opts -code] == 10} {
    puts "STA_STATUS check=$check_name status=NO_CLOCKS wns=NA tns=NA violating_paths=0 total=0"
    puts "NOTE: no clock object exists; create_clock is required before STA."
  } else {
    puts "STA_STATUS check=$check_name status=SCRIPT_ERROR wns=NA tns=NA violating_paths=0 total=0"
    puts "ERROR: [dict get $err_opts -errorinfo]"
  }
} else {
  sta_print_summary $check_name $paths [sta_summarize $paths] $sta_fail_slack $sta_csv
}
