# GTKWave 交互式分析的批处理等价操作：信号搜索、沿查找、marker 测时间差、
# 缩放、值翻译过滤器、信号高亮、双 VCD 标签页基线对照
# 注意：3.3.116 无头模式下 findNextEdge 依赖 GUI 选中态、结果不可复现，
# 沿查找统一走 signalChangeList（与界面 Search -> Find Next Edge 看到的是同一份跳变数据）。
proc P {s} {puts $s; flush stdout}
gtkwave::loadFile wave_a.vcd

# ---- 1) SST 信号搜索：遍历 facility 用正则过滤（等价 Search -> Signal Search Regexp）----
set hits {}
set nfacs [gtkwave::getNumFacs]
for {set i 0} {$i < $nfacs} {incr i} {
    set nm [gtkwave::getFacName $i]
    if {[regexp {full|empty|fire_} $nm]} { lappend hits $nm }
}
P "SEARCH_HITS: [llength $hits] -> $hits"
catch {gtkwave::forceOpenTreeNode {tb.dut}}

# ---- 2) 加入要观察的信号 ----
gtkwave::addSignalsFromList [list \
    {tb.clk} {tb.wr_en} {tb.dut.fire_wr} {tb.rd_en} {tb.dut.fire_rd} \
    {tb.dut.cnt[2:0]} {tb.dut.full} {tb.dut.empty}]
P "TRACES: [gtkwave::getTotalNumTraces] time_range_ps: [gtkwave::getMinTime]..[gtkwave::getMaxTime] dimension=[gtkwave::getTimeDimension]"

# ---- 3) 沿查找：从 full 的跳变表枚举全部边沿（等价反复 Find Next Edge）----
set edges {}
set prev ""
foreach {t v} [gtkwave::signalChangeList {tb.dut.full}] {
    if {$t > 1000000000000000} continue
    if {$prev ne "" && $prev ne $v} { lappend edges "$t/$v" }
    set prev $v
}
P "FULL_EDGES: $edges"

# ---- 4) marker 测时间差：full 上升沿放 baseline marker、下降沿放主 marker ----
set rise -1; set fall -1; set prev ""
foreach {t v} [gtkwave::signalChangeList {tb.dut.full}] {
    if {$t > 1000000000000000} continue
    if {$prev eq "0" && $v eq "1"} { set rise $t }
    if {$prev eq "1" && $v eq "0"} { set fall $t }
    set prev $v
}
gtkwave::setBaselineMarker $rise
gtkwave::setMarker $fall
set delta_ps [expr {[gtkwave::getMarker] - [gtkwave::getBaselineMarker]}]
P [format "FULL_ASSERT_PS: %d" $rise]
P [format "FULL_DEASSERT_PS: %d" $fall]
P [format "FULL_DURATION_NS: %.1f (primary=%d baseline=%d)" [expr {$delta_ps/1000.0}] $fall $rise]

# ---- 5) 握手间隔：fire_rd 相邻上升沿之间的时间差（找消费者停顿）----
set rtimes {}; set prev ""
foreach {t v} [gtkwave::signalChangeList {tb.dut.fire_rd}] {
    if {$t > 1000000000000000} continue
    if {$prev eq "0" && $v eq "1"} { lappend rtimes $t }
    set prev $v
}
set gaps {}
for {set i 1} {$i < [llength $rtimes]} {incr i} {
    lappend gaps [expr {([lindex $rtimes $i] - [lindex $rtimes $i-1]) / 1000.0}]
}
set rns {}
foreach x $rtimes { lappend rns [expr {$x/1000.0}] }
P "RD_RISING_TIMES_NS: $rns"
P "RD_HANDSHAKE_GAPS_NS: $gaps"

# ---- 5b) 导出 A 的跳变表，供与 B 做文本基线对照 ----
foreach {sig out} [list {tb.dut.full} full_a.txt {tb.dut.fire_rd} firerd_a.txt] {
    set f [open $out w]
    foreach {t v} [gtkwave::signalChangeList $sig] {
        if {$t > 1000000000000000} continue
        puts $f "$t $v"
    }
    close $f
}
P "BASELINE_EXPORT_A: full_a.txt firerd_a.txt"

# ---- 6) 缩放：先全屏，再把窗口放到 full 有效的区间 ----
gtkwave::/Time/Zoom/Zoom_Full
P "ZOOM_FULL_WINDOW_NS: [expr {[gtkwave::getWindowStartTime]/1000.0}]..[expr {[gtkwave::getWindowEndTime]/1000.0}]"
gtkwave::setZoomRangeTimes [expr {$rise - 20000}] [expr {$fall + 20000}]
P "ZOOM_MARKED_WINDOW_NS: [expr {[gtkwave::getWindowStartTime]/1000.0}]..[expr {[gtkwave::getWindowEndTime]/1000.0}]"

# ---- 7) 值翻译过滤器：cnt 的数值映射成文字；再正则高亮满/空标志 ----
set h [gtkwave::installFileFilter cnt_filter.txt]
gtkwave::setCurrentTranslateFile $h
P "TRANSLATE_FILTER_INSTALLED: handle=$h"
gtkwave::setTraceHighlightFromNameMatch {full|empty} 1
P "HIGHLIGHT_APPLIED: full|empty"

# ---- 8) 保存分析现场（信号列表、格式、marker 位置）；必须在开新标签页之前，
#         否则 save 记录的是新活动标签的空白视图（3.3.116 实测）----
gtkwave::/File/Write_Save_File_As analysis.gtkw
P "SAVE_WRITTEN: analysis.gtkw"

# ---- 9) 双 VCD 基线对照：开第二个标签页载入场景 B ----
gtkwave::/File/Open_New_Tab wave_b.vcd
P "TABS_OPEN: [gtkwave::getNumTabs] (A=fast drain, B=slow drain)"
gtkwave::/File/Quit
