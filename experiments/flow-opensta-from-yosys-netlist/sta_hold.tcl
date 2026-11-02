read_liberty teaching.lib
read_verilog netlist.v
link_design  top
read_sdc     constraints.sdc
report_checks -path_delay min -digits 3
