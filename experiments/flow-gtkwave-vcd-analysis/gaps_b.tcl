# 场景 B：fire_rd 相邻上升沿间隔（读 1 拍停 1 拍，预期稳定 20ns）
gtkwave::loadFile wave_b.vcd
set times {}
set prev ""
foreach {t v} [gtkwave::signalChangeList {tb.dut.fire_rd}] {
    if {$t > 1000000000000000} continue
    if {$prev eq "0" && $v eq "1"} { lappend times $t }
    set prev $v
}
set gaps {}
for {set i 1} {$i < [llength $times]} {incr i} {
    lappend gaps [expr {([lindex $times $i]-[lindex $times $i-1])/1000.0}]
}
puts "B_RD_RISING_TIMES_NS: $times"
puts "B_RD_HANDSHAKE_GAPS_NS: $gaps"
gtkwave::/File/Quit
