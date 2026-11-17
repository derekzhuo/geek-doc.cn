load_package flow
project_new -overwrite pp_warn -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE pin_design.v
set_global_assignment -name TOP_LEVEL_ENTITY pp_top
execute_flow -compile
project_close
