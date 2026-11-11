# 错误 6：-waveform 必须是偶数个边沿点，这里给了 3 个
create_clock -name clk -period 10.0 -waveform {0.0 3.0 6.0} [get_ports clk]
