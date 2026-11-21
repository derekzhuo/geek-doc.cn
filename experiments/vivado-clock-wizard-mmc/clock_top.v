`timescale 1ns/1ps
module clock_top (
    input wire clk100,
    input wire reset,
    output wire clk50,
    output wire clk200,
    output wire locked,
    output reg [7:0] count50 = 0,
    output reg [7:0] count200 = 0
);
clk_wiz_0 clocks (
    .clk_in1(clk100),
    .reset(reset),
    .clk_out1(clk50),
    .clk_out2(clk200),
    .locked(locked)
);
always @(posedge clk50) begin
    if (reset) count50 <= 0;
    else count50 <= count50 + 1'b1;
end
always @(posedge clk200) begin
    if (reset) count200 <= 0;
    else count200 <= count200 + 1'b1;
end
endmodule
