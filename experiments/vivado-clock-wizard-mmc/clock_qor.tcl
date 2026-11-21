set root [pwd]
set part xc7a35ticsg324-1L
file mkdir "$root/work/implementation"
cd "$root/work/implementation"
create_project -in_memory -part $part
read_ip "$root/work/ip/.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci"
generate_target all [get_ips clk_wiz_0]
synth_ip [get_ips clk_wiz_0]
read_verilog "$root/clock_top.v"
read_xdc "$root/constraints.xdc"
synth_design -top clock_top -part $part
opt_design
place_design
route_design
report_clocks -file clocks.rpt
report_utilization -file utilization.rpt
report_timing_summary -file timing.rpt
foreach {port expected} {clk50 20.000 clk200 5.000} {
    set matched [get_clocks -of_objects [get_ports $port]]
    if {[llength $matched] != 1} {
        error "Expected one generated clock on $port, got $matched"
    }
    set actual [get_property PERIOD $matched]
    if {abs($actual - $expected) > 0.001} {
        error "Unexpected $port period: $actual ns, expected $expected ns"
    }
    puts "CLOCK_DERIVED port=$port name=$matched period_ns=$actual"
}
set wns [get_property SLACK [get_timing_paths -setup -max_paths 1 -nworst 1]]
set whs [get_property SLACK [get_timing_paths -hold -max_paths 1 -nworst 1]]
if {$wns eq "" || $whs eq "" || $wns < 0 || $whs < 0} {
    error "Post-route timing failed or missing: WNS=$wns WHS=$whs"
}
puts "CLOCK_QOR_OK input_mhz=100 outputs_mhz=50,200 wns=$wns whs=$whs"
exit
