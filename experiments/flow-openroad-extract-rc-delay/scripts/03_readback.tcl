source scripts/common.tcl
read_physical results/01_placed.def
read_spef -name global_rc results/02_global_route.spef
report_parasitic_annotation -name global_rc -report_unannotated
snap spef_readback
puts "STAGE_03_SPEF_READBACK_OK"
exit
