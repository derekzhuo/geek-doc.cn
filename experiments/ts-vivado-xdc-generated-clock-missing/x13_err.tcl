read_verilog clock_div.v
read_xdc clocks_bad.xdc
synth_design -top clock_div -part xc7a35tcpg236-1
report_clocks
report_clock_interaction
report_timing_summary -max_paths 3
