# 场景一：违例网表 + 紧周期 1.2ns，四级 BUF 路径到达 1.40ns
read_liberty teaching.lib
read_verilog build/netlist_top_bad.v
link_design top
create_clock -name clk -period 1.2 [get_ports clk]
puts "=== CASE bad: period 1.2ns, worst setup path ==="
report_checks -path_delay max -fields {slew capacitance}
puts "=== CASE bad: unconstrained endpoints ==="
report_checks -unconstrained
