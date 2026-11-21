load_package flow
project_new -overwrite clock_bad -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE blink.v
set_global_assignment -name SDC_FILE bad.sdc
set_global_assignment -name TOP_LEVEL_ENTITY blink
execute_flow -compile
project_close
