puts "BROKEN_CASE_1: truncated liberty file (unbalanced braces)"
if {[catch {read_liberty broken.lib} msg]} {
  puts "Tcl result: $msg"
}

puts "BROKEN_CASE_2: Verilog netlist fed to read_liberty"
if {[catch {read_liberty top.v} msg]} {
  puts "Tcl result: $msg"
}

puts "BROKEN_CASE_3: gzip-compressed liberty without gunzip first"
if {[catch {read_liberty mini.lib.gz} msg]} {
  puts "Tcl result: $msg"
}

puts "BROKEN_CASE_4: corner name ff was never defined by define_corners"
if {[catch {read_liberty -corner ff minimal.lib} msg]} {
  puts "Tcl result: $msg"
}
