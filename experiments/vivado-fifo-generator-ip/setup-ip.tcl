set root [pwd]
set part xc7a35ticsg324-1L
file mkdir "$root/work/ip"
cd "$root/work/ip"
create_project -in_memory -part $part
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_16x8
set_property -dict [list \
    CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
    CONFIG.Input_Data_Width {8} \
    CONFIG.Input_Depth {16} \
    CONFIG.Output_Data_Width {8} \
    CONFIG.Output_Depth {16} \
    CONFIG.Reset_Type {Synchronous_Reset} \
    CONFIG.Almost_Full_Flag {true} \
    CONFIG.Almost_Empty_Flag {true}] [get_ips fifo_16x8]
generate_target all [get_ips fifo_16x8]
set ipdir "$root/work/ip/.srcs/sources_1/ip/fifo_16x8"
foreach file [list "$ipdir/fifo_16x8.xci" "$ipdir/sim/fifo_16x8.v" "$ipdir/hdl/fifo_generator_v13_2_rfs.v" "$ipdir/simulation/fifo_generator_vlog_beh.v"] {
    if {![file exists $file]} { error "Missing generated FIFO file: $file" }
}
foreach {property expected} {CONFIG.Fifo_Implementation Common_Clock_Block_RAM CONFIG.Input_Data_Width 8 CONFIG.Input_Depth 16 CONFIG.Output_Data_Width 8 CONFIG.Output_Depth 16} {
    set actual [get_property $property [get_ips fifo_16x8]]
    if {$actual != $expected} { error "Unexpected $property: $actual" }
}
puts "FIFO_IP_READY width=8 depth=16 implementation=block_ram"
exit
