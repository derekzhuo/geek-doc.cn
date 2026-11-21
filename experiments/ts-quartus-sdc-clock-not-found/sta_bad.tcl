project_open clock_bad
create_timing_netlist
read_sdc
update_timing_netlist
report_clocks
report_timing -setup -npaths 3 -detail full_path
project_close
