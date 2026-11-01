read_liberty tiny.lib
read_verilog top2.v
link_design top2
source constraints_met.sdc
# Waiver margin: require WNS >= 2.0 ns instead of merely non-negative.
set sta_fail_slack 2.0
source extract_sta_summary.tcl
