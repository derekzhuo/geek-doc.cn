puts "================ CLOCK ROLES ================"
puts "core_clk: source port clk; board_clk: virtual, no design source"
puts "================ RX SETUP ================"
report_checks -path_delay max -from [get_ports uart_rx] -to [get_cells u_rx]
puts "================ RX HOLD ================"
report_checks -path_delay min -from [get_ports uart_rx] -to [get_cells u_rx]
puts "================ TX SETUP ================"
report_checks -path_delay max -from [get_cells u_tx] -to [get_ports uart_tx]
puts "================ TX HOLD ================"
report_checks -path_delay min -from [get_cells u_tx] -to [get_ports uart_tx]
