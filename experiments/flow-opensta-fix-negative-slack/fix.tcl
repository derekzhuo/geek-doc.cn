# 场景三：插了一级流水寄存器的新网表，周期维持 1.2ns（改 RTL 后重新综合）
read_liberty teaching.lib
read_verilog build/netlist_top_fix.v
link_design top
create_clock -name clk -period 1.2 [get_ports clk]
puts "=== CASE pipelined: period 1.2ns, worst setup path ==="
report_checks -path_delay max -endpoint_count 2
puts "=== CASE pipelined: hold ==="
report_checks -path_delay min
