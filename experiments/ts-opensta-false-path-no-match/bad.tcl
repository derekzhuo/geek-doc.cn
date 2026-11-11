source common.tcl
puts "CASE: bad separator (u_b.D)"
source bad.sdc
report_checks -unconstrained -fields {slew input_pins} -digits 3
