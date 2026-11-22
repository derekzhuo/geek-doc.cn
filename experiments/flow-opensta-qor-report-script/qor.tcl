# qor.tcl -- OpenSTA QoR batch summary (verified on OpenSTA 2.0.17).
# Source this file AFTER read_liberty/read_verilog/link_design and the SDC
# (the SDC must create the path groups listed in qor_groups).
#
# Parameters (set before sourcing, or edit the defaults):
#   qor_groups        path groups created by group_path, plus the default clk group
#   qor_max_paths     endpoints collected per group per check
#   qor_skew_limit    max allowed clock skew across register clock pins (ns)
#   qor_setup_margin  minimum allowed setup WNS (ns)
#   qor_hold_margin   minimum allowed hold WNS (ns)
#   qor_work_dir      scratch directory for per-pin report_checks files

if {![info exists qor_groups]}       { set qor_groups {CTRL DATA clk} }
if {![info exists qor_max_paths]}    { set qor_max_paths 50 }
if {![info exists qor_skew_limit]}   { set qor_skew_limit 0.50 }
if {![info exists qor_setup_margin]} { set qor_setup_margin 0.0 }
if {![info exists qor_hold_margin]}  { set qor_hold_margin 0.0 }
if {![info exists qor_work_dir]}     { set qor_work_dir "results/tmp" }
file mkdir $qor_work_dir

# Floating-point guard: values inside 1 femtosecond of zero count as zero.
set qor_eps 1.0e-6

proc qor_pin_clock_arrival {dpin work_dir} {
  # Path objects expose only slack/startpoint/endpoint, so the per-pin clock
  # arrival is read from a full report_checks: the LAST "clock network delay"
  # line is the capture-side arrival at this endpoint's clock pin.
  set safe [string map {/ _} $dpin]
  set tmpfile [file join $work_dir "arr_${safe}.txt"]
  report_checks -path_delay max -to $dpin -digits 4 > $tmpfile
  set fh [open $tmpfile r]
  set txt [read $fh]
  close $fh
  # -line anchors ^ per line; the first column (Incr) of the capture-side
  # clock network delay line is the pure insertion latency at this clock pin.
  set matches [regexp -line -all -inline \
    {^\s*([0-9]+(?:\.[0-9]+)?)\s+[0-9.]+\s+clock network delay} $txt]
  if {[llength $matches] == 0} {
    error "no clock network delay found for $dpin"
  }
  lindex $matches end
}

proc qor_skew_table {work_dir} {
  puts "================ CLOCK SKEW TABLE ================"
  puts "QOR_SKEW,pin,arrival_ns,skew_to_lead_ns"
  set rows {}
  set lead ""
  foreach inst [all_registers] {
    set iname [get_property $inst full_name]
    set dpin "${iname}/D"
    if {[catch {get_pins $dpin}]} continue
    set arr [qor_pin_clock_arrival $dpin $work_dir]
    lappend rows [list "${iname}/C" $arr]
    if {$lead eq "" || $arr < $lead} { set lead $arr }
  }
  set trail $lead
  foreach row [lsort -dictionary -index 0 $rows] {
    lassign $row clkpin arr
    set skew [expr {$arr - $lead}]
    puts [format "QOR_SKEW,%s,%.4f,%.4f" $clkpin $arr $skew]
    if {$arr > $trail} { set trail $arr }
  }
  set global_skew [expr {$trail - $lead}]
  puts [format "QOR_SKEW_SUMMARY,lead_ns=%.4f,trail_ns=%.4f,global_skew_ns=%.4f" \
    $lead $trail $global_skew]
  return $global_skew
}

proc qor_group_check {group check max_paths eps} {
  set paths [find_timing_paths -unique_paths_to_endpoint \
    -group_count $max_paths -path_delay $check -path_group $group \
    -sort_by_slack]
  set total [llength $paths]
  if {$total == 0} {
    return [list 0 "" 0.0 0.0 "-" "-"]
  }
  set wns ""
  set tns 0.0
  set violating 0
  set worst_sp "-"
  set worst_ep "-"
  foreach path $paths {
    set slack [get_property $path slack]
    if {$wns eq "" || $slack < $wns} {
      set wns $slack
      set sp [get_property $path startpoint]
      set ep [get_property $path endpoint]
      set worst_sp [get_property $sp full_name]
      set worst_ep [get_property $ep full_name]
    }
    if {$slack < -$eps} {
      set tns [expr {$tns + $slack}]
      incr violating
    }
  }
  list $total $wns $tns $violating $worst_sp $worst_ep
}

proc qor_group_tables {groups max_paths eps} {
  puts "================ PER-GROUP QOR TABLE ================"
  puts "QOR_GROUP,group,check,endpoints,wns_ns,tns_ns,violating,worst_start,worst_end"
  set setup_wns ""
  set hold_wns ""
  foreach group $groups {
    foreach check {max min} {
      set r [qor_group_check $group $check $max_paths $eps]
      lassign $r total wns tns violating worst_sp worst_ep
      if {$total == 0} {
        puts [format "QOR_GROUP,%s,%s,0,NA,NA,0,-,-" $group $check]
        continue
      }
      puts [format "QOR_GROUP,%s,%s,%d,%.4f,%.4f,%d,%s,%s" \
        $group $check $total $wns $tns $violating $worst_sp $worst_ep]
      if {$check eq "max"} {
        if {$setup_wns eq "" || $wns < $setup_wns} { set setup_wns $wns }
      } else {
        if {$hold_wns eq "" || $wns < $hold_wns} { set hold_wns $wns }
      }
    }
  }
  list $setup_wns $hold_wns
}

# Coverage audit: every register D pin must appear in some constrained group.
proc qor_coverage_audit {groups max_paths} {
  puts "================ ENDPOINT COVERAGE AUDIT ================"
  set covered {}
  foreach group $groups {
    set paths [find_timing_paths -unique_paths_to_endpoint \
      -group_count $max_paths -path_delay max -path_group $group]
    foreach path $paths {
      set ep [get_property $path endpoint]
      lappend covered [get_property $ep full_name]
    }
  }
  set missing {}
  foreach inst [all_registers] {
    set dpin "[get_property $inst full_name]/D"
    if {[catch {get_pins $dpin}]} continue
    if {$dpin ni $covered} { lappend missing $dpin }
  }
  puts [format "QOR_COVERAGE,registers=%d,missing=%d" \
    [llength [all_registers]] [llength $missing]]
  foreach dpin $missing { puts "QOR_MISSING_ENDPOINT,$dpin" }
}

# Built-in cross-check: OpenSTA 2.0.17 report_clock_skew prints only the first
# clock-pin pair it visits; the full table above is the scripted complement.
puts "================ BUILT-IN report_clock_skew ================"
report_clock_skew -setup -digits 4
report_clock_skew -hold -digits 4

set global_skew [qor_skew_table $qor_work_dir]
lassign [qor_group_tables $qor_groups $qor_max_paths $qor_eps] setup_wns hold_wns
qor_coverage_audit $qor_groups $qor_max_paths

puts "================ QOR GATE ================"
if {$setup_wns eq ""} { set setup_wns 0.0 }
if {$hold_wns eq ""}  { set hold_wns 0.0 }
set setup_pass [expr {$setup_wns >= $qor_setup_margin - $qor_eps}]
set hold_pass  [expr {$hold_wns >= $qor_hold_margin - $qor_eps}]
set skew_pass  [expr {$global_skew <= $qor_skew_limit + $qor_eps}]
set overall [expr {$setup_pass && $hold_pass && $skew_pass}]
puts [format "QOR_GATE,setup=%s,hold=%s,skew=%s,overall=%s,setup_wns=%.4f,hold_wns=%.4f,global_skew=%.4f" \
  [expr {$setup_pass ? "PASS" : "FAIL"}] \
  [expr {$hold_pass ? "PASS" : "FAIL"}] \
  [expr {$skew_pass ? "PASS" : "FAIL"}] \
  [expr {$overall ? "PASS" : "FAIL"}] \
  $setup_wns $hold_wns $global_skew]
