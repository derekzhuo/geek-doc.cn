# drc-bad.tcl — 故意制造 metal1 间距违例：两条 0.5um 宽金属间距仅 0.03um
# sky130A full DRC 风格 met1.2 间距阈值 0.14um，预期报 Metal1 spacing 违例
drc off
snap user 0.001
box 0um 0um 0.5um 2um
paint met1
box 0.53um 0um 1.03um 2um
paint met1
crashbackups stop
drc euclidean on
drc style drc(full)
drc on
drc catchup
puts "=== DRC VIOLATIONS (bad) ==="
set allerrors [drc listall why]
foreach {whytext rectlist} $allerrors {
    puts $whytext
    foreach rect $rectlist {
        puts "  rect: $rect"
    }
}
puts "=== TOTAL: [llength $allerrors] rule hits ==="
quit
