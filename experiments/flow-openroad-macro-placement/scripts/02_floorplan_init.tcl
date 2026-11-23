# 流程二：网表驱动，initialize_floorplan 自动建 die area 与 row
read_liberty fixtures/teaching.lib
read_lef fixtures/tech.lef
read_lef fixtures/sram64.lef
read_lef fixtures/sram40.lef
read_verilog fixtures/top.v
link_design top_macro

set block [ord::get_db_block]
puts "STAGE0 insts=[llength [$block getInsts]] rows=[llength [$block getRows]]"

initialize_floorplan -die_area {0 0 200 200} -core_area {10 10 190 190} -site unit

set die [$block getDieArea]
puts "STAGE1 rows=[llength [$block getRows]] die_um=([$die xMin] [$die yMin])-([expr {[$die xMax]/2000.0}] [expr {[$die yMax]/2000.0}])"

make_tracks metal1 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal2 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal3 -x_pitch 0.28 -y_pitch 0.28

foreach inst [$block getInsts] {
  puts "STAGE2 before_place inst=[$inst getName] status=[$inst getPlacementStatus]"
}
place_macro -macro_name u_sram0 -location {20 20} -orientation R0 -exact
place_macro -macro_name u_sram1 -location {120 20} -orientation R0 -exact
foreach inst [$block getInsts] {
  lassign [$inst getLocation] loc_x loc_y
  puts "STAGE3 after_place inst=[$inst getName] status=[$inst getPlacementStatus] origin_um=\{[expr {$loc_x/2000.0}] [expr {$loc_y/2000.0}]\}"
}
check_placement
write_def results/02_floorplan.def
puts "FLOW_02_OK"
exit
