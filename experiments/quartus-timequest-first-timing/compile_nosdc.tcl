load_package flow
project_new -overwrite timing_nosdc -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE ripple_chain.v
set_global_assignment -name TOP_LEVEL_ENTITY ripple_chain
execute_flow -compile
project_close
