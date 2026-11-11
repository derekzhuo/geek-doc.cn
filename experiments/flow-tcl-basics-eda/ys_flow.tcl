# Yosys 同样把 Tcl 作为脚本语言：yosys -p "tcl ys_flow.tcl"
# 注意入口不是 yosys -c：tcl pass 里要先 yosys -import 把综合命令导入解释器
yosys -import

set rtl_files [list rtl/gates.v rtl/cnt.v]

# foreach 批量读入多个 RTL 文件，新增文件只改上面一行列表
foreach f $rtl_files {
    puts ">>> read_verilog $f"
    read_verilog $f
}

# proc：Tcl 自带过程定义（yosys 的 proc pass 因同名被改名为 procs）
proc show_stat {mod} {
    puts "===== stat $mod ====="
    stat $mod
}

# foreach 遍历模块名列表，逐模块出面积/单元统计
foreach m [list gate_demo cnt4] {
    show_stat $m
}

# 命令查询：-import 后 yosys 命令已成为真正的 Tcl 命令，可按通配符列出
puts "===== info commands synth* ====="
foreach cmd [lsort [info commands synth*]] {
    puts $cmd
}
