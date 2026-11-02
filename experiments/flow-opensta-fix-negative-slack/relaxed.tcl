# 场景二：同一张违例网表，只把周期放松到 2.0ns（改约束）
read_liberty teaching.lib
read_verilog build/netlist_top_bad.v
link_design top
create_clock -name clk -period 2.0 [get_ports clk]
puts "=== CASE relaxed: period 2.0ns, same netlist, setup ==="
report_checks -path_delay max
puts "=== CASE relaxed: hold ==="
report_checks -path_delay min
