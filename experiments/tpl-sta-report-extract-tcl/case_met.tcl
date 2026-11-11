read_liberty tiny.lib
read_verilog top2.v
link_design top2
source constraints_met.sdc
source extract_sta_summary.tcl
