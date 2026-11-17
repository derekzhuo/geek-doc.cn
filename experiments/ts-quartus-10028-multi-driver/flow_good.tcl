load_package flow
project_new -overwrite qdrv_good -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE md_good.v
set_global_assignment -name TOP_LEVEL_ENTITY md_top
execute_flow -compile
project_close
