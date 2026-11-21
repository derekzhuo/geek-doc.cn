load_package flow
project_new -overwrite multicycle_demo -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE pipeline.v
set_global_assignment -name SDC_FILE baseline.sdc
set_global_assignment -name TOP_LEVEL_ENTITY pipeline
execute_flow -compile
project_close
