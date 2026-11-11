read_liberty tiny.lib
read_verilog top2.v
link_design top2
source constraints_vio.sdc
set sta_path_delay "max"
source extract_sta_summary.tcl
