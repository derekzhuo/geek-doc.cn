read_lef fixtures/tech.lef
read_lef fixtures/cells.lef
read_liberty fixtures/teaching.lib
read_verilog fixtures/top.v
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
set_power_activity -input -activity 0.1 -duty 0.5
puts "POWER_CASE vectorless_default input_activity=0.1 duty=0.5 clock_ns=10"
report_power -digits 9
report_power -instances {u_and u_xor} -digits 9
