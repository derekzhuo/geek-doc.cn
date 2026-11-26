# 阶段一：构造欠优设计并给出修复前基线时序（OpenROAD 26Q4）
# 高扇出网表（1 个源缓冲驱动 40 个负载）+ 全局布局 + 连线 RC 估计 + 虚拟时钟约束
read_liberty fixtures/teaching.lib
read_lef fixtures/tech.lef
read_lef fixtures/stdcell.lef
read_verilog fixtures/top.v
link_design top

initialize_floorplan -die_area {0 0 300 300} -core_area {10 10 290 290} -site unit
make_tracks metal1 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal2 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal3 -x_pitch 0.28 -y_pitch 0.28
place_pins -hor_layers metal3 -ver_layers metal2
global_placement -density 0.4

# 无工艺 RC 表，用 set_wire_rc 给出单位长度电阻（ohm/um 量级教学值）与电容（pF/um 量级）
set_wire_rc -resistance 0.5 -capacitance 0.001
estimate_parasitics -placement

# 虚拟时钟：组合路径用 input/output delay 约束，无需真实 CTS
create_clock -name vclk -period 0.9
set_input_delay -clock vclk -max 0.2 [all_inputs]
set_input_delay -clock vclk -min 0.0 [all_inputs]
set_output_delay -clock vclk -max 0.2 [all_outputs]
# 负的 min output delay 用于建模外部器件的保持时间要求（标准 SDC 写法）
set_output_delay -clock vclk -min -0.4 [get_ports z_short]

proc snap {tag} {
  set block [ord::get_db_block]
  set n 0
  foreach i [$block getInsts] { incr n }
  puts "SLAP round=$tag insts=$n setup_wns=[format %.4f [sta::worst_slack -max]] setup_tns=[format %.4f [sta::total_negative_slack -max]] hold_wns=[format %.4f [sta::worst_slack -min]] hold_tns=[format %.4f [sta::total_negative_slack -min]]"
}

puts "==== BASELINE 修复前时序（全局布局 + 连线估计后） ===="
snap 0
puts "---- setup 最差路径（max 分析） ----"
report_checks -path_delay max -endpoint_path_count 1 -format short
puts "---- hold 最差路径（min 分析，z_short） ----"
report_checks -path_delay min -to z_short -endpoint_path_count 1 -format short
write_def results/01_baseline.def
puts "FLOW_01_OK"
exit
