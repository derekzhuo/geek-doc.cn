read_verilog false_path_design.v
read_xdc false_path.xdc
synth_design -top false_path_design -part xc7a35tcpg236-1
report_timing -from [get_cells stage_reg] -to [get_cells q_reg] -max 1
report_timing_summary -max_paths 3
