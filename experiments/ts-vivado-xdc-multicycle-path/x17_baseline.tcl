read_verilog mcp_path.v
read_xdc mcp_baseline.xdc
synth_design -top mcp_path -part xc7a35tcpg236-1
report_timing -from [get_cells stage_reg] -to [get_cells q_reg] -max 1
