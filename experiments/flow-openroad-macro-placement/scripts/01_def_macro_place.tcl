# 流程一：DEF 驱动的宏单元摆放（OpenROAD 26Q4）
# 输入只带 DIEAREA 与两个 UNPLACED 宏实例，row 与轨道在 Tcl 侧补齐
read_lef fixtures/tech.lef
read_lef fixtures/sram64.lef
read_lef fixtures/sram40.lef
read_def fixtures/design_unplaced.def

set block [ord::get_db_block]

# DEF 夹具未带 ROWS：用 odb 接口补 200 条 1um 高的标准单元行（等价 DEF ROW 语句）
if {[llength [$block getRows]] == 0} {
  set site [[lindex [[ord::get_db] getLibs] 0] findSite unit]
  for {set i 0} {$i < 200} {incr i} {
    odb::dbRow_create $block "core_row_$i" $site 0 [expr {$i*2000}] "R0" "HORIZONTAL" 200 2000
  }
}

# 该镜像 ODB 的 LEF 解析器不接受 LEF TRACKS 语句，轨道网格改在 Tcl 侧建立
make_tracks metal1 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal2 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal3 -x_pitch 0.28 -y_pitch 0.28

puts "==== STAGE1 摆放前：两个宏均为 UNPLACED ===="
foreach inst [$block getInsts] {
  puts "STAGE1 inst=[$inst getName] master=[[$inst getMaster] getName] status=[$inst getPlacementStatus] origin_dbu=[$inst getLocation]"
}

puts "==== STAGE2 place_macro -exact 精确摆放 ===="
place_macro -macro_name u_sram0 -location {20 20} -orientation R0 -exact
place_macro -macro_name u_sram1 -location {120 20} -orientation R0 -exact
foreach inst [$block getInsts] {
  set bbox [$inst getBBox]
  lassign [$inst getLocation] loc_x loc_y
  puts "STAGE2 inst=[$inst getName] status=[$inst getPlacementStatus] origin_um=\{[expr {$loc_x/2000.0}] [expr {$loc_y/2000.0}]\} bbox_um=([expr {[$bbox xMin]/2000.0}] [expr {[$bbox yMin]/2000.0}])-([expr {[$bbox xMax]/2000.0}] [expr {[$bbox yMax]/2000.0}])"
}

puts "==== STAGE3 block_macro_channels 生成软阻挡 ===="
block_macro_channels
foreach blk [$block getBlockages] {
  set bbox [$blk getBBox]
  puts "STAGE3 blockage soft=[$blk isSoft] bbox_um=([expr {[$bbox xMin]/2000.0}] [expr {[$bbox yMin]/2000.0}])-([expr {[$bbox xMax]/2000.0}] [expr {[$bbox yMax]/2000.0}])"
}
check_placement
write_def results/01_placed_no_halo.def

puts "==== STAGE4 set_halo 每侧 10um（参数顺序 left bottom right top） ===="
set_halo -halo {10 10 10 10} -instance u_sram0
set_halo -halo {10 10 10 10} -instance u_sram1
foreach inst [$block getInsts] {
  set hb [$inst getHalo]
  puts "STAGE4 inst=[$inst getName] halo_um L=[$hb xMin] B=[$hb yMin] R=[$hb xMax] T=[$hb yMax]"
}
write_def results/01_placed_halo.def
puts "FLOW_01_OK"
exit
