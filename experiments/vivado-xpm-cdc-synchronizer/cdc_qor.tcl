set root [pwd]
set part xc7a35ticsg324-1L
foreach variant {xpm hand} {
    set work "$root/work/$variant"
    file mkdir $work
    cd $work
    read_verilog "$root/cdc_${variant}.v"
    read_xdc "$root/constraints.xdc"
    synth_design -top "cdc_${variant}" -part $part
    foreach cell [get_cells -hier -filter {ASYNC_REG == TRUE}] {
        puts "CDC_ATTRIBUTE variant=$variant cell=$cell ASYNC_REG=[get_property ASYNC_REG $cell]"
    }
    opt_design
    place_design
    route_design
    report_utilization -file utilization.rpt
    report_timing_summary -file timing.rpt
    puts "CDC_QOR_RESULT variant=$variant"
    close_design
}
exit
