load_package flow
project_new -overwrite vccio_good -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE io_conflict.v
set_global_assignment -name TOP_LEVEL_ENTITY ic_top
set_location_assignment PIN_23 -to clk
set_location_assignment PIN_24 -to rst_n
set_location_assignment PIN_87 -to led_a
set_location_assignment PIN_86 -to led_b
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led_a
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led_b
execute_flow -compile
project_close
