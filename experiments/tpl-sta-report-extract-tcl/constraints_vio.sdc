# Tightened clock: at a 2 ns period both long chains violate setup.
create_clock -name clk -period 2 [get_ports clk]
