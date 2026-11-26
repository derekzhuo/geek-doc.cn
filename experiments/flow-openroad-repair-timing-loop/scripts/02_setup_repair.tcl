# 阶段二：setup 修复闭环（repair_design 迭代 + 每轮重估寄生参数）
# 从阶段一写出的 DEF 接续，保证每轮看到的是同一个设计的连续演化
read_liberty fixtures/teaching.lib
read_lef fixtures/tech.lef
read_lef fixtures/stdcell.lef
read_def results/01_baseline.def

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

puts "==== SETUP 阶段起点（应与阶段一基线一致） ===="
snap r0
master_hist

puts "==== SETUP round 1: repair_design -max_wire_length 20 ===="
repair_design -max_wire_length 20
estimate_parasitics -placement
snap r1
master_hist

puts "==== SETUP round 2: 同一命令再跑一轮（幂等性/收敛判据） ===="
repair_design -max_wire_length 20
estimate_parasitics -placement
snap r2
master_hist

write_def results/02_setup_fixed.def
puts "FLOW_02_OK"
exit
