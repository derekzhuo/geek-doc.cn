if {[catch {open_vcd continuation.vcd} msg]} {
    puts "CONTINUATION_VCD_OPEN_FAILED $msg"
    quit
}
if {[catch {log_vcd /tb_toggle/dut/*} msg]} {
    puts "CONTINUATION_VCD_LOG_FAILED $msg"
    catch {close_vcd}
    quit
}
if {[catch {run all} msg]} {
    puts "CONTINUATION_RUN_FAILED $msg"
    catch {close_vcd}
    quit
}
if {[catch {close_vcd} msg]} {
    puts "CONTINUATION_VCD_CLOSE_FAILED $msg"
    quit
}
quit
