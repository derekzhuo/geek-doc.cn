# 场景二：同一设计把时钟提到 0.5ns 周期，数据路径 0.50 不变，
# 预期 setup slack = 0.5 - 0.5 - 0.1 = -0.10 VIOLATED
read_liberty teaching.lib
read_verilog top.v
link_design top
create_clock -name clk -period 0.5 [get_ports clk]
puts "=== CASE fast: period 0.5ns, setup (path_delay max) ==="
report_checks -path_delay max
