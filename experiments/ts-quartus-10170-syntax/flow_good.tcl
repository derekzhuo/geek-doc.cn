load_package flow
project_new -overwrite qerr_good -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE led_good.v
set_global_assignment -name TOP_LEVEL_ENTITY led_blink
execute_flow -compile
project_close
