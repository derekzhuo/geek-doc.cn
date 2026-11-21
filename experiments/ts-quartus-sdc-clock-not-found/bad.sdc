create_clock -name clk_wrong -period 20.000 [get_ports clk_missing]
derive_clock_uncertainty
