# 流程三：halo 对 global placement 避让效果的对照实验
# 模式由环境变量 GP_MODE 传入：nohalo（不设 halo）或 halo（每侧 10um）
set mode $::env(GP_MODE)
read_liberty fixtures/teaching.lib
read_lef fixtures/tech.lef
read_lef fixtures/sram64.lef
read_lef fixtures/sram40.lef
read_lef fixtures/stdcell.lef
read_verilog fixtures/top_gp.v
link_design top_gp
initialize_floorplan -die_area {0 0 200 200} -core_area {10 10 190 190} -site unit
make_tracks metal1 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal2 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal3 -x_pitch 0.28 -y_pitch 0.28
place_macro -macro_name u_sram0 -location {20 20} -orientation R0 -exact
place_macro -macro_name u_sram1 -location {120 20} -orientation R0 -exact
if {$mode eq "halo"} {
  set_halo -halo {10 10 10 10} -instance u_sram0
  set_halo -halo {10 10 10 10} -instance u_sram1
  puts "MODE=halo_10um_per_side"
} else {
  puts "MODE=no_halo"
}

# global placement 要求顶层端口先落位
place_pins -hor_layers metal3 -ver_layers metal2
global_placement -density 0.6

set block [ord::get_db_block]
# 两模式共用同一组评估盒：halo 外环盒（本体外扩 10um）与宏本体盒
set halo_boxes [list [list 10 10 90 90] [list 110 10 170 90]]
set body_boxes [list [list 20 20 80 80] [list 120 20 160 80]]
set in_halo 0
set in_body 0
set total 0
proc in_any {x y boxes} {
  foreach box $boxes {
    lassign $box x0 y0 x1 y1
    if {$x >= $x0 && $x <= $x1 && $y >= $y0 && $y <= $y1} { return 1 }
  }
  return 0
}
foreach inst [$block getInsts] {
  if {[$inst isBlock]} { continue }
  incr total
  lassign [$inst getLocation] loc_x loc_y
  set x [expr {$loc_x/2000.0}]
  set y [expr {$loc_y/2000.0}]
  if {[in_any $x $y $halo_boxes]} { incr in_halo }
  if {[in_any $x $y $body_boxes]} { incr in_body }
}
puts "GP_RESULT mode=$mode core_cells=$total in_halo_band=$in_halo in_macro_body=$in_body"
write_def results/03_gp_$mode.def
puts "FLOW_03_OK"
exit
