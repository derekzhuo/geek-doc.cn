# 全部板级参数均为本篇教学假设，不是任何通用 UART 器件数据手册参数。
# core_clk 是 DUT 内部寄存器真实使用的时钟，绑定到 clk 端口。
create_clock -name core_clk -period 10.0 -waveform {0.0 5.0} [get_ports clk]
# board_clk 只描述片外器件的 launch/capture 参考沿，不绑定设计端口。
create_clock -name board_clk -period 10.0 -waveform {0.0 5.0}

# RX setup: tCO(max) 2.00 + data trace 0.35 + skew allowance 0.10 = 2.45 ns
# RX hold:  tCO(min) 0.40 + data trace 0.35 - skew allowance 0.10 = 0.65 ns
set_input_delay 2.45 -max -clock board_clk [get_ports uart_rx]
set_input_delay 0.65 -min -clock board_clk [get_ports uart_rx]

# TX setup: receiver tSU 1.20 + data trace 0.35 + skew allowance 0.10 = 1.65 ns
# TX hold: -receiver tH 0.40 + data trace 0.35 - skew allowance 0.10 = -0.15 ns
set_output_delay 1.65 -max -clock board_clk [get_ports uart_tx]
set_output_delay -0.15 -min -clock board_clk [get_ports uart_tx]
