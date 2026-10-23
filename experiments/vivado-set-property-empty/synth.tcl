read_verilog counter.v
read_xdc [lindex $argv 0]
synth_design -top counter -part xc7a35tcpg236-1
