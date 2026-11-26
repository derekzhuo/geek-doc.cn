read_lef fixtures/tech.lef
read_lef fixtures/cells.lef
read_liberty fixtures/teaching.lib
read_verilog fixtures/top.v
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
read_saif -scope tb/dut results/activity.saif
puts "POWER_CASE measured_saif scope=tb/dut duration_ns=90"
report_power -digits 9
report_power -instances {u_and u_xor} -digits 9
