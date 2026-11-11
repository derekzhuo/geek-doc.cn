# 场景三：周期 2.0ns 不变，给时钟加 0.20ns 网络延迟（理想时钟上的设定值），
# 发射沿与捕获沿平移相同，slack 不变；只用于观察 clock network latency 字段
read_liberty teaching.lib
read_verilog top.v
link_design top
create_clock -name clk -period 2.0 [get_ports clk]
set_clock_latency 0.20 [get_clocks clk]
puts "=== CASE latency: set_clock_latency 0.20, setup (path_delay max) ==="
report_checks -path_delay max
