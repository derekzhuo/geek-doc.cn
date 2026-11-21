set root [pwd]
set part xc7a35ticsg324-1L
foreach depth {0 1 2 3} {
    set work "$root/work/pipe$depth"
    file mkdir $work
    cd $work
    set t0 [clock milliseconds]
    read_verilog "$root/dsp_pipeline.v"
    read_xdc "$root/constraints.xdc"
    synth_design -top "dsp_pipe$depth" -part $part
    opt_design
    place_design
    route_design
    report_utilization -file utilization.rpt
    report_timing_summary -file timing.rpt
    set elapsed [expr {([clock milliseconds] - $t0) / 1000.0}]
    puts "DSP_QOR_RESULT pipeline=$depth elapsed_sec=$elapsed"
    close_design
}
exit
