load_package flow
project_new -overwrite pp_fixed -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE pin_design.v
set_global_assignment -name TOP_LEVEL_ENTITY pp_top
set_location_assignment PIN_23 -to clk
set_location_assignment PIN_24 -to rst_n
set_location_assignment PIN_87 -to led[0]
set_location_assignment PIN_86 -to led[1]
set_location_assignment PIN_85 -to led[2]
set_location_assignment PIN_84 -to led[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led[3]
execute_flow -compile
project_close
