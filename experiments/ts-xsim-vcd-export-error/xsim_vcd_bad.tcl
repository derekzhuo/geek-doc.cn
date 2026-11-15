if {[catch {log_vcd /tb_toggle/dut/*} msg]} {
  puts "EXPECTED_SIMULATOR_45_10 $msg"
  quit
}
run all
close_vcd
quit
