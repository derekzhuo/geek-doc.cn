load_package flow
project_new -overwrite clock_good -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE blink.v
set_global_assignment -name SDC_FILE good.sdc
set_global_assignment -name TOP_LEVEL_ENTITY blink
execute_flow -compile
project_close
