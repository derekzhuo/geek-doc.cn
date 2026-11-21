project_open multicycle_demo
create_timing_netlist
read_sdc paired.sdc
update_timing_netlist
report_timing -setup -from [get_cells stage_reg] -to [get_cells q~reg0] -npaths 1 -detail full_path
report_timing -hold -from [get_cells stage_reg] -to [get_cells q~reg0] -npaths 1 -detail full_path
project_close
