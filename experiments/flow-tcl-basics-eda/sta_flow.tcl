# OpenSTA 里的 Tcl 最小可用集：变量 / 列表 / foreach / proc / 命令查询
# 运行：sta -no_init -exit sta_flow.tcl

# 1) 变量：set 名字 值，用 $名字 取值
set lib_file tiny.lib
set netlist  top.v
set top      top
set period   10.0

read_liberty $lib_file
read_verilog $netlist
link_design  $top
create_clock -name clk -period $period [get_ports clk]

# 2) 列表：list 构造，lappend 追加；这里是一个普通 Tcl 字符串列表
set corners [list max]       ;# list 构造列表
lappend corners min          ;# lappend 追加元素，列表变成 {max min}

# 3) proc：把「打标题 + 报告」封装成一个带两个参数的过程
proc report_corner {corner digits} {
  variable period            ;# 引用全局变量 period
  puts "----- report_checks -path_delay $corner, period=${period}ns -----"
  report_checks -path_delay $corner -digits $digits
}

# 4) foreach：遍历 Tcl 列表，对每个角点跑一次封装好的报告
foreach c $corners {
  report_corner $c 3
}

# 5) 集合不是列表：all_registers 返回 STA 对象集合，
#    OpenSTA 2.0.17 没有 PrimeTime 的 foreach_in_collection，
#    直接用普通 foreach 逐项取出对象句柄，再用 get_property 取属性
puts "----- foreach over \[all_registers\] + get_property -----"
foreach reg [all_registers] {
  puts [get_property $reg full_name]
}

# 6) 命令查询：info commands 按通配符列出当前解释器里真实存在的命令
puts "----- info commands report_* -----"
foreach cmd [lsort [info commands report_*]] {
  puts $cmd
}
puts "----- help report_checks (head) -----"
help report_checks
