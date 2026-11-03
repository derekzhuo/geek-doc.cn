`timescale 1ns/1ps
module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output reg        tx_ready,
    output reg        txd
);
  // 教学用最小占位 IP，仅演示 vendor 版本管理
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin tx_ready <= 1'b1; txd <= 1'b1; end
  end
endmodule
