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
detailed_placement
set_routing_layers -signal metal1-$top_layer
global_route -guide_file $tag.guide -allow_congestion -congestion_iterations 5 -verbose
detailed_route -output_drc $tag.drc.rpt -droute_end_iter $end_iter -verbose 1
puts "PROBE tag=$tag top_layer=$top_layer"
