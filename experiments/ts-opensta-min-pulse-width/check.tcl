if {![info exists env(SDC_FILE)]} {
  error "SDC_FILE is required"
}
read_liberty experiment.lib
read_verilog top.v
link_design top
read_sdc $env(SDC_FILE)
puts "CASE_SDC: $env(SDC_FILE)"
report_clock_properties
puts "MIN_PULSE_WIDTH_CHECKS"
report_pulse_width_checks
