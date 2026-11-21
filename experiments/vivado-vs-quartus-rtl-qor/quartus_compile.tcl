load_package flow
set root [pwd]
set work "$root/work/quartus"
file mkdir $work
cd $work
project_new -overwrite fifo_cross -family "Cyclone IV E" -part EP4CE6E22C8
set_global_assignment -name VERILOG_FILE "$root/fifo_hand.v"
set_global_assignment -name SDC_FILE "$root/constraints.sdc"
set_global_assignment -name TOP_LEVEL_ENTITY fifo_hand
execute_flow -compile
project_close
