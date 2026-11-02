# First-STA command sequence: liberty -> netlist -> link -> SDC -> reports.
read_liberty tiny.lib
read_verilog  top.v
link_design   top
read_sdc      constraints.sdc

puts "=== clocks ==="
report_clock_properties
puts "=== setup report (path_delay max) ==="
report_checks -path_delay max -digits 3
puts "=== hold report (path_delay min) ==="
report_checks -path_delay min -digits 3
