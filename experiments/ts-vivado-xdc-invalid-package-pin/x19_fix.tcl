read_verilog clock_gate.v
read_xdc pins_ok.xdc
synth_design -top clock_gate -part xc7a35tcpg236-1
opt_design
place_design
puts "X19_FIX_PLACE_DONE"
