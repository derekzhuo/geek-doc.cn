# 场景一：周期 2.0ns，数据路径 0.20(DFF CLK->Q) + 0.30(BUF) = 0.50，
# 库 setup 0.10，预期 setup slack = 2.0 - 0.5 - 0.1 = 1.40 MET
read_liberty teaching.lib
read_verilog top.v
link_design top
create_clock -name clk -period 2.0 [get_ports clk]
puts "=== CASE met: period 2.0ns, setup (path_delay max) ==="
report_checks -path_delay max
puts "=== CASE met: hold (path_delay min) ==="
report_checks -path_delay min
