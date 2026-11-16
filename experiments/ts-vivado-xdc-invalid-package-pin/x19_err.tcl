read_verilog clock_gate.v
read_xdc pins_bad.xdc
synth_design -top clock_gate -part xc7a35tcpg236-1
opt_design
place_design
puts "X19_BAD_FLOW_REACHED_END"
