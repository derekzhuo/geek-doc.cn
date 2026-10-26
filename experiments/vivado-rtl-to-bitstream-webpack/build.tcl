# Vivado project-mode batch flow: RTL -> synth -> impl -> bitstream
# run: vivado -mode batch -source build.tcl -log vivado_build.log -journal vivado_build.jou
create_project blink ./blink_proj -part xc7a35tcsg324-1 -force
add_files [pwd]/top.v
add_files -fileset constrs_1 [pwd]/top.xdc

launch_runs synth_1
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

open_run impl_1
report_utilization -file [pwd]/util.rpt
report_timing_summary -file [pwd]/timing.rpt -warn_on_violation

puts "FLOW_DONE bit=[glob -nocomplain ./blink_proj/blink.runs/impl_1/*.bit]"
