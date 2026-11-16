read_verilog bank_probe.v
read_xdc fixed.xdc
synth_design -top bank_probe -part xc7a35tcpg236-1
report_property [get_ports a]
report_property [get_ports b]
report_property [get_iobanks 14]
opt_design
place_design
