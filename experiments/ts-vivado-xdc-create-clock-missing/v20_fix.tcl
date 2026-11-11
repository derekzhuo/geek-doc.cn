read_verilog clock_gate.v
read_xdc clocks_ok.xdc
synth_design -top clock_gate -part xc7a35tcpg236-1
report_clocks
