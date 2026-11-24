read_liberty cts.lib
read_lef tech.lef
read_lef stdcell.lef
read_verilog top.v
link_design top
initialize_floorplan -die_area {0 0 40 40} -core_area {2 2 38 38} -site unit
make_tracks metal1 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal2 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal3 -x_pitch 0.28 -y_pitch 0.28
place_pins -hor_layers metal3 -ver_layers metal2
global_placement -density 0.4
create_clock -name clk -period 10 [get_ports clk]
set_propagated_clock [all_clocks]
set_wire_rc -clock -layer metal2
clock_tree_synthesis -buf_list BUF_X1 -root_buf BUF_X1 -apply_ndr none
report_clock_skew -setup -digits 6
set block [ord::get_db_block]
puts "PROBE buffers=[llength [get_cells -filter {ref_name == BUF_X1}]] instances=[llength [$block getInsts]]"
