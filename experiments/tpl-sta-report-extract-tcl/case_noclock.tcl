read_liberty tiny.lib
read_verilog top.v
link_design top
# No create_clock on purpose: exercise the unconstrained-design branch.
source extract_sta_summary.tcl
