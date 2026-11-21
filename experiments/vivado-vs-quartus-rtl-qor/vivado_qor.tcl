set root [pwd]
set work "$root/work/vivado"
file mkdir $work
cd $work
create_project -in_memory -part xc7a35ticsg324-1L
read_verilog "$root/fifo_hand.v"
read_xdc "$root/constraints.xdc"
synth_design -top fifo_hand -part xc7a35ticsg324-1L
opt_design
place_design
route_design
report_utilization -file utilization.rpt
report_timing_summary -file timing.rpt
set wns [get_property SLACK [get_timing_paths -setup -max_paths 1 -nworst 1]]
set whs [get_property SLACK [get_timing_paths -hold -max_paths 1 -nworst 1]]
if {$wns eq "" || $whs eq ""} { error "Missing Vivado timing paths" }
if {$wns < 0 || $whs < 0} { error "Negative Vivado timing: WNS=$wns WHS=$whs" }
set ram_count [llength [get_cells -hier -filter {REF_NAME =~ RAMB*}]]
puts "VIVADO_QOR_RESULT block_rams=$ram_count wns=$wns whs=$whs"
close_design
exit
