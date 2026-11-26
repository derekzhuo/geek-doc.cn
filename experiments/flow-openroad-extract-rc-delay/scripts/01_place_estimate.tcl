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
detailed_placement
source fixtures/io.sdc
set_wire_rc -resistance 5.0 -capacitance 0.001
estimate_parasitics -placement
source scripts/common.tcl
snap placement
write_def results/01_placed.def
puts "STAGE_01_PLACEMENT_OK"
exit
