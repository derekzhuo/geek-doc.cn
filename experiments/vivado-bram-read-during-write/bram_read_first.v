`timescale 1ns/1ps

module bram_read_first (
    input wire clk,
    input wire we,
    input wire [7:0] addr,
    input wire [15:0] din,
    output reg [15:0] dout
);
(* ram_style = "block" *) reg [15:0] mem [0:255];
always @(posedge clk) begin
    if (we) mem[addr] <= din;
    dout <= mem[addr];
end
endmodule
