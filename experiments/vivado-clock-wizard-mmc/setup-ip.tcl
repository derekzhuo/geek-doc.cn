set root [pwd]
set part xc7a35ticsg324-1L
file mkdir "$root/work/ip"
cd "$root/work/ip"
create_project -in_memory -part $part
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 5.4 -module_name clk_wiz_0
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true}] [get_ips clk_wiz_0]
set ip [get_ips clk_wiz_0]
generate_target all $ip
set ipdir "$root/work/ip/.srcs/sources_1/ip/clk_wiz_0"
foreach file [list "$ipdir/clk_wiz_0.xci" "$ipdir/clk_wiz_0.v" "$ipdir/clk_wiz_0_clk_wiz.v"] {
    if {![file exists $file]} { error "Missing generated Clocking Wizard file: $file" }
}
foreach {property expected} {CONFIG.PRIM_IN_FREQ 100.000 CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 50.000 CONFIG.CLKOUT2_REQUESTED_OUT_FREQ 200.000} {
    set actual [get_property $property $ip]
    if {$actual != $expected} { error "Unexpected $property: $actual" }
}
puts "CLOCK_IP_READY input_mhz=100 clk50_mhz=50 clk200_mhz=200"
exit
