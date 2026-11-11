puts "VALID_CASE: read_liberty minimal.lib then read_verilog and link"
read_liberty minimal.lib
read_verilog top.v
link_design top
puts "LINK_OK: minimal.lib accepted and top linked"

create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 1.0 -clock clk [get_ports d]
set_output_delay 1.0 -clock clk [get_ports q]

report_clock_properties
check_setup -verbose
report_checks
