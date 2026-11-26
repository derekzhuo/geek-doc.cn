read_lef fixtures/tech.lef
read_lef fixtures/cells.lef
read_liberty fixtures/teaching.lib
read_verilog fixtures/top.v
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
puts "BOUNDARY_CASE wrong_scope=tb/missing_dut"
read_saif -scope tb/missing_dut results/activity.saif
puts "BOUNDARY_AFTER_READ_SAIF command returned"
report_power -digits 6
