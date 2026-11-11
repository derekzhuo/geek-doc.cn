# drc-good.tcl — 同结构把间距放宽到 0.20um（>met1.2 的 0.14um 阈值），预期 0 违例
drc off
snap user 0.001
box 0um 0um 0.5um 2um
paint met1
box 0.7um 0um 1.2um 2um
paint met1
crashbackups stop
drc euclidean on
drc style drc(full)
drc on
drc catchup
puts "=== DRC VIOLATIONS (good) ==="
set allerrors [drc listall why]
foreach {whytext rectlist} $allerrors {
    puts $whytext
    foreach rect $rectlist {
        puts "  rect: $rect"
    }
}
puts "=== TOTAL: [llength $allerrors] rule hits ==="
quit
