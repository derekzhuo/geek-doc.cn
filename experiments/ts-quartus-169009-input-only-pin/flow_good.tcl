load_package flow
project_new -overwrite pdir_good -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE pin_dir.v
set_global_assignment -name TOP_LEVEL_ENTITY pd_top
set_location_assignment PIN_23 -to clk
set_location_assignment PIN_24 -to rst_n
set_location_assignment PIN_87 -to led
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led
execute_flow -compile
project_close
