source scripts/common.tcl
read_physical results/01_placed.def
set_wire_rc -resistance 5.0 -capacitance 0.001
set_routing_layers -signal metal1-metal3
global_route -guide_file results/02_global_route.guide -allow_congestion
estimate_parasitics -global_routing -spef_file results/02_global_route.spef
snap global_route
puts "STAGE_02_GLOBAL_ROUTE_SPEF_OK"
exit
