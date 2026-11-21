set root [pwd]
set part xc7a35ticsg324-1L
foreach variant {ip hand} {
    set work "$root/work/$variant"
    file mkdir $work
    cd $work
    create_project -in_memory -part $part
    if {$variant eq "ip"} {
        read_ip "$root/work/ip/.srcs/sources_1/ip/fifo_16x8/fifo_16x8.xci"
        generate_target all [get_ips fifo_16x8]
        synth_ip [get_ips fifo_16x8]
        read_verilog "$root/fifo_ip_top.v"
        set top fifo_ip_top
    } else {
        read_verilog "$root/fifo_hand.v"
        set top fifo_hand
    }
    read_xdc "$root/constraints.xdc"
    synth_design -top $top -part $part
    opt_design
    place_design
    route_design
    report_utilization -file utilization.rpt
    report_timing_summary -file timing.rpt
    set wns [get_property SLACK [get_timing_paths -setup -max_paths 1 -nworst 1]]
    set whs [get_property SLACK [get_timing_paths -hold -max_paths 1 -nworst 1]]
    if {($wns ne "" && $wns < 0) || ($whs ne "" && $whs < 0)} {
        error "Negative post-route timing for $variant: WNS=$wns WHS=$whs"
    }
    set ram_count [llength [get_cells -hier -filter {REF_NAME =~ RAMB*}]]
    if {$ram_count != 1} {
        error "Expected one block RAM for $variant, got $ram_count"
    }
    puts "FIFO_RAM_OK variant=$variant block_rams=$ram_count"
    puts "FIFO_QOR_RESULT variant=$variant wns=$wns whs=$whs"
    close_design
}
exit
