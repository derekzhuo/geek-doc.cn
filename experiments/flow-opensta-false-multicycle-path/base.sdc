create_clock -name clk -period 0.60 -waveform {0.00 0.30} [get_ports clk]
set_clock_uncertainty -setup 0.00 [get_clocks clk]
set_clock_uncertainty -hold 0.00 [get_clocks clk]
