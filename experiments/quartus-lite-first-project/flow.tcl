# Quartus 批处理全流程：建工程 -> 指定器件/源码/引脚 -> 全编译 -> 摘资源报告
project_new -overwrite led_blink
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE6E22C8
set_global_assignment -name TOP_LEVEL_ENTITY led_blink
set_global_assignment -name VERILOG_FILE led_blink.v
set_location_assignment PIN_23 -to clk
set_location_assignment PIN_24 -to rst_n
set_location_assignment PIN_25 -to led
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to led
load_package flow
execute_flow -compile
if {[file exists led_blink.fit.summary]} {
    post_message "===== led_blink.fit.summary ====="
    set fp [open led_blink.fit.summary r]
    post_message [read $fp]
    close $fp
}
project_close
