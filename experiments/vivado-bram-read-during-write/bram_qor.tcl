set root [pwd]
set part xc7a35ticsg324-1L
foreach variant {write_first read_first no_change} {
    set work "$root/work/$variant"
    file mkdir $work
    cd $work
    set t0 [clock milliseconds]
    read_verilog "$root/bram_${variant}.v"
    read_xdc "$root/constraints.xdc"
    synth_design -top "bram_${variant}" -part $part
    opt_design
    place_design
    route_design
    report_utilization -file utilization.rpt
    report_timing_summary -file timing.rpt
    set elapsed [expr {([clock milliseconds] - $t0) / 1000.0}]
    puts "BRAM_QOR_RESULT variant=$variant elapsed_sec=$elapsed"
    close_design
}
exit
