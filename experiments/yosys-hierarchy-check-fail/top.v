// top.v —— 顶层：例化一个参数化的 fifo 子模块
module top #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             wr_en,
    input  wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout,
    output wire             full,
    output wire             empty
);

  // 参数化例化：WIDTH 由顶层参数传下去
  fifo #(
      .WIDTH(WIDTH),
      .DEPTH(16)
  ) u_fifo (
      .clk   (clk),
      .rst_n (rst_n),
      .wr_en (wr_en),
      .rd_en (~empty),
      .din   (din),
      .dout  (dout),
      .full  (full),
      .empty (empty)
  );

endmodule
