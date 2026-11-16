read_verilog constraint_order.v
read_xdc level_18.xdc
read_xdc level_33.xdc
synth_design -top constraint_order -part xc7a35tcpg236-1
report_property [get_ports en]
