# 通用跳变表导出：场景由环境变量 SCENE 决定（A=快排空，B=慢排空）
# 用法：SCENE=A xvfb-run gtkwave -S export_full.tcl；脚本内按 SCENE 选波形与输出名
set scene $::env(SCENE)
if {$scene eq "A"} {
    gtkwave::loadFile wave_a.vcd
} else {
    gtkwave::loadFile wave_b.vcd
}
foreach {sig out} [list {tb.dut.full} full_${scene}.txt {tb.dut.fire_rd} firerd_${scene}.txt] {
    set f [open $out w]
    foreach {t v} [gtkwave::signalChangeList $sig] {
        if {$t > 1000000000000000} continue
        puts $f "$t $v"
    }
    close $f
}
puts "EXPORT_SCENE_${scene}: full_${scene}.txt firerd_${scene}.txt"
gtkwave::/File/Quit
