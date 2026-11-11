// FIFO 顶层：只做一层例化，演示多文件工程要指定 --top-module
module fifo_top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       wr_en,
    input  wire       rd_en,
    input  wire [7:0] din,
    output wire [7:0] dout,
    output wire       full,
    output wire       empty
);
    sync_fifo #(
        .WIDTH(8),
        .DEPTH(4)
    ) u_fifo (
        .clk   (clk),
        .rst_n (rst_n),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .din   (din),
        .dout  (dout),
        .full  (full),
        .empty (empty)
    );
endmodule
