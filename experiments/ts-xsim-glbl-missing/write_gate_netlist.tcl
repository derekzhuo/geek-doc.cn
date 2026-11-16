read_verilog glbl_probe.v
synth_design -top glbl_probe -part xc7a35tcpg236-1
write_verilog -force gate_netlist.v
puts "GATE_NETLIST_WRITTEN"
