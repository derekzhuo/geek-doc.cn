read_liberty tiny.lib
read_verilog top.v
link_design top
read_sdc base.sdc
puts "clocks=[all_clocks]"
report_clock_properties [all_clocks]
report_checks
