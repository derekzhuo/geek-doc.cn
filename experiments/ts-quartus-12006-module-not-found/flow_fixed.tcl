load_package flow
project_new -overwrite qmod_good -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE sub_divider.v
set_global_assignment -name VERILOG_FILE top_blink.v
set_global_assignment -name TOP_LEVEL_ENTITY top_blink
execute_flow -compile
project_close
