read_verilog sdf_probe.v
synth_design -top sdf_probe -part xc7a35tcpg236-1
opt_design
place_design
route_design
write_verilog -mode timesim -sdf_anno true -sdf_file timesim.sdf -force timesim_netlist.v
write_sdf -force timesim.sdf
exit
