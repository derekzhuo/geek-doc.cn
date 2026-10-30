set root [file dirname [info script]]
read_liberty "$root/experiment.lib"
read_verilog "$root/fixed.v"
link_design top
create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 1.0 -clock clk [get_ports d]
set_output_delay 1.0 -clock clk [get_ports y]
report_checks
