# non-project flow, one pass per constraint variant
# usage: vivado -mode batch -source run_pass.tcl -tclargs <loose|tight> -log vivado_<mode>.log
set mode [lindex $argv 0]

read_verilog [pwd]/pipe.v
read_xdc [pwd]/${mode}.xdc

synth_design -top wide_lut_chain -part xc7a35tcsg324-1
opt_design
place_design
route_design

report_timing_summary -file [pwd]/timing_${mode}.rpt -warn_on_violation
write_checkpoint -force [pwd]/routed_${mode}.dcp

puts "PASS_DONE ${mode}"
