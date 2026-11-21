# 可选的第二种外部工作模式：同一 RX 额外允许 board_clk 下降沿发射。
# 这不是标准 UART 的隐含属性，只是演示 -clock_fall 与 -add_delay 的独立教学假设。
# 下降沿模式 tCO(max)=3.00 ns、tCO(min)=1.00 ns；保留已有上升沿约束。
set_input_delay 3.00 -max -clock board_clk -clock_fall -add_delay [get_ports uart_rx]
set_input_delay 1.00 -min -clock board_clk -clock_fall -add_delay [get_ports uart_rx]
