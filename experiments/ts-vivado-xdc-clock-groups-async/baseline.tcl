read_verilog async_clock_groups.v
read_xdc baseline.xdc
synth_design -top async_clock_groups -part xc7a35tcpg236-1
report_clock_interaction
report_timing -from [get_cells stage_reg] -to [get_cells q_reg] -max 1
report_timing_summary -max_paths 3
