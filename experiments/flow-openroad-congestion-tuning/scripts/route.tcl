set tag $env(TAG)
set density $env(DENSITY)
read_liberty fixtures/teaching.lib
read_lef fixtures/tech.lef
read_lef fixtures/stdcell.lef
read_verilog fixtures/top.v
link_design top
initialize_floorplan -die_area {0 0 16 16} -core_area {2 2 14 14} -site unit
make_tracks metal1 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal2 -x_pitch 0.28 -y_pitch 0.28
make_tracks metal3 -x_pitch 0.28 -y_pitch 0.28
place_pins -hor_layers metal3 -ver_layers metal2
puts "RUN_CONFIG tag=$tag density=$density"
global_placement -density $density
detailed_placement
write_def results/$tag.placed.def
set_routing_layers -signal metal1-metal3
set_global_routing_layer_adjustment metal1 0.4
set_global_routing_layer_adjustment metal2 0.4
set_global_routing_layer_adjustment metal3 0.4
global_route -guide_file results/$tag.guide -congestion_report_file results/$tag.congestion.rpt -congestion_report_iter_step 1 -allow_congestion -congestion_iterations 10 -verbose
detailed_route -output_drc results/$tag.drc.rpt -droute_end_iter 10 -verbose 1
puts "ROUTE_COMPLETE tag=$tag"
