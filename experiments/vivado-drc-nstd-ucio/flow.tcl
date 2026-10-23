read_verilog counter.v
if {[llength $argv] > 0} { read_xdc [lindex $argv 0] }
synth_design -top counter -part xc7a35tcpg236-1
opt_design
place_design
route_design
write_bitstream -force counter.bit
