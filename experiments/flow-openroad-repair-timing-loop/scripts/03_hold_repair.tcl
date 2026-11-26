# 阶段三：hold 修复（repair_timing -hold 插入延迟缓冲，setup 结果不回退）
read_liberty fixtures/teaching.lib
read_lef fixtures/tech.lef
read_lef fixtures/stdcell.lef
read_def results/02_setup_fixed.def

set_wire_rc -resistance 0.5 -capacitance 0.001
estimate_parasitics -placement

create_clock -name vclk -period 0.9
set_input_delay -clock vclk -max 0.2 [all_inputs]
set_input_delay -clock vclk -min 0.0 [all_inputs]
set_output_delay -clock vclk -max 0.2 [all_outputs]
set_output_delay -clock vclk -min -0.4 [get_ports z_short]

proc snap {tag} {
  set block [ord::get_db_block]
  set n 0
  foreach i [$block getInsts] { incr n }
  puts "SLAP round=$tag insts=$n setup_wns=[format %.4f [sta::worst_slack -max]] setup_tns=[format %.4f [sta::total_negative_slack -max]] hold_wns=[format %.4f [sta::worst_slack -min]] hold_tns=[format %.4f [sta::total_negative_slack -min]]"
}
proc master_hist {} {
  set block [ord::get_db_block]
  set hist {}
  foreach i [$block getInsts] {
    set m [[$i getMaster] getName]
    dict incr hist $m
  }
  foreach m [lsort [dict keys $hist]] { puts "MASTER_HIST $m=[dict get $hist $m]" }
}

puts "==== HOLD 阶段起点（setup 修复后 hold 可能被扰动） ===="
snap h0
master_hist

puts "==== HOLD round 1: repair_timing -hold ===="
repair_timing -hold
estimate_parasitics -placement
snap h1
master_hist

puts "---- 修复后 hold 最差路径（min 分析，z_short） ----"
report_checks -path_delay min -to z_short -endpoint_path_count 1 -format short
write_def results/03_final.def
puts "FLOW_03_OK"
exit
