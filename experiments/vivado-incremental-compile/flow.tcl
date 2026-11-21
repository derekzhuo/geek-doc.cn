set mode [lindex $argv 0]
set variant [lindex $argv 1]
set run [lindex $argv 2]
set root [pwd]
set part xc7a35ticsg324-1L
if {$mode eq "baseline"} {
    set work "$root/baseline"
} else {
    set work "$root/work/${variant}_${mode}_${run}"
}
file mkdir $work
cd $work
set leaf base
set top base
if {$variant eq "small"} {
    set leaf small
} elseif {$variant eq "large"} {
    set top large
}
set t0 [clock milliseconds]
read_verilog "$root/src/leaf_${leaf}.v"
read_verilog "$root/src/top_${top}.v"
read_xdc "$root/src/constraints.xdc"
synth_design -top top -part $part
write_checkpoint -force postsynth.dcp
if {$mode eq "incremental"} {
    close_design
    open_checkpoint "$work/postsynth.dcp"
}
opt_design
if {$mode eq "incremental"} {
    read_checkpoint -incremental "$root/baseline/postroute.dcp"
}
place_design
route_design
report_utilization -file utilization.rpt
report_timing_summary -file timing.rpt
if {$mode eq "incremental"} {
    report_incremental_reuse -file reuse.rpt
}
write_checkpoint -force postroute.dcp
set elapsed [expr {([clock milliseconds] - $t0) / 1000.0}]
puts "EXPERIMENT_RESULT variant=$variant mode=$mode run=$run elapsed_sec=$elapsed"
exit
