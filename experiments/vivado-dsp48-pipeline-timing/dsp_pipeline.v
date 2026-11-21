`timescale 1ns/1ps

module dsp_pipe0 (
    input wire clk,
    input wire signed [15:0] a,
    input wire signed [15:0] b,
    (* dont_touch = "true" *) output reg signed [31:0] y
);
always @(posedge clk) y <= a * b;
endmodule

module dsp_pipe1 (
    input wire clk,
    input wire signed [15:0] a,
    input wire signed [15:0] b,
    (* dont_touch = "true" *) output reg signed [31:0] y
);
reg signed [31:0] p0;
always @(posedge clk) begin
    p0 <= a * b;
    y <= p0;
end
endmodule

module dsp_pipe2 (
    input wire clk,
    input wire signed [15:0] a,
    input wire signed [15:0] b,
    (* dont_touch = "true" *) output reg signed [31:0] y
);
reg signed [31:0] p0;
reg signed [31:0] p1;
always @(posedge clk) begin
    p0 <= a * b;
    p1 <= p0;
    y <= p1;
end
endmodule

module dsp_pipe3 (
    input wire clk,
    input wire signed [15:0] a,
    input wire signed [15:0] b,
    (* dont_touch = "true" *) output reg signed [31:0] y
);
reg signed [31:0] p0;
reg signed [31:0] p1;
reg signed [31:0] p2;
always @(posedge clk) begin
    p0 <= a * b;
    p1 <= p0;
    p2 <= p1;
    y <= p2;
end
endmodule
