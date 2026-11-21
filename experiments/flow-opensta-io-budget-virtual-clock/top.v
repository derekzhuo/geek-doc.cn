// 同一个同步 UART 外壳网表：RX 经一个与非门级采样，TX 由寄存器经缓冲输出。
// 仅用于说明板级 IO 时序预算，不实现 UART 波特率、帧格式或 CDC。
module top (
  input  wire clk,
  input  wire uart_rx,
  output wire uart_tx
);
  wire rx_mux;
  wire tx_q;
  DFF_P u_rx (.C(clk), .D(rx_mux), .Q());
  NAND2 u_rx_buf (.A(uart_rx), .B(uart_rx), .Y(rx_mux));
  DFF_P u_tx (.C(clk), .D(uart_rx), .Q(tx_q));
  BUF_X u_tx_buf (.A(tx_q), .Y(uart_tx));
endmodule
