puts "MISSING_CASE_1: relative path ./lib/not_here.lib (cwd is the run directory)"
if {[catch {read_liberty ./lib/not_here.lib} msg]} {
  puts "Tcl result: $msg"
}

puts "MISSING_CASE_2: path built from unset env var STA_LIB"
if {[catch {read_liberty $::env(STA_LIB)/minimal.lib} msg]} {
  puts "Tcl result: $msg"
}
