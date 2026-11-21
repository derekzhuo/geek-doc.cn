`timescale 1ns/1ps
module fifo_ip_top (
    input wire clk,
    input wire srst,
    input wire [7:0] din,
    input wire wr_en,
    input wire rd_en,
    output wire [7:0] dout,
    output wire full,
    output wire almost_full,
    output wire empty,
    output wire almost_empty
);
    fifo_16x8 fifo_inst (
        .clk(clk), .srst(srst), .din(din), .wr_en(wr_en), .rd_en(rd_en),
        .dout(dout), .full(full), .almost_full(almost_full),
        .empty(empty), .almost_empty(almost_empty)
    );
endmodule
