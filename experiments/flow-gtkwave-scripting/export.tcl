# GTKWave 批处理脚本：加信号、导出信号清单与跳变表、写 save 文件
# 用法：xvfb-run gtkwave -S export.tcl wave.vcd
gtkwave::loadFile wave.vcd

# 1) 按层次路径把信号加进波形窗口（顺序即显示顺序）
gtkwave::addSignalsFromList [list \
    {tb_counter.clk} \
    {tb_counter.rst_n} \
    {tb_counter.cnt[7:0]} \
    {tb_counter.co}]
puts "DISPLAYED: [gtkwave::getDisplayedSignals]"
puts "TOTAL_TRACES: [gtkwave::getTotalNumTraces]"

# 2) 遍历 dump 里全部 facility，导出纯文本信号清单
set nfacs [gtkwave::getNumFacs]
set f [open facs.txt w]
puts $f "# index dir name vtype dtype"
for {set i 0} {$i < $nfacs} {incr i} {
    puts $f "$i [gtkwave::getFacDir $i] [gtkwave::getFacName $i] [gtkwave::getFacVtype $i] [gtkwave::getFacDtype $i]"
}
close $f
puts "FACS_EXPORTED: $nfacs -> facs.txt"

# 3) 导出 cnt 总线在 0..212000ps 内的每次跳变（时间戳 十六进制值）
set changes [gtkwave::signalChangeList {tb_counter.cnt[7:0]}]
set cf [open cnt_changes.txt w]
puts $cf {# time(ps) value(hex) of tb_counter.cnt[7:0]}
foreach {t v} $changes { puts $cf "$t $v" }
close $cf
puts "CNT_CHANGES: [expr {[llength $changes] / 2}] rows -> cnt_changes.txt"

# 4) 把当前布局写成 save 文件（等价 File -> Write Save File As）
gtkwave::/File/Write_Save_File_As layout.gtkw
puts "SAVE_WRITTEN: layout.gtkw"

gtkwave::/File/Quit
