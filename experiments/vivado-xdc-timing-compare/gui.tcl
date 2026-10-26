# open routed tight-constraint checkpoint in GUI and raise the Timing Summary tab
open_checkpoint [pwd]/routed_tight.dcp
report_timing_summary -name timing_0 -warn_on_violation
puts "GUI_TIMING_OPEN"
