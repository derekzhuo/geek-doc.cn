`timescale 1ns/1ps
// 4 x 8 位寄存器堆：同步写、异步读
module regfile (
    input  wire       clk,
    input  wire       we,
    input  wire [1:0] waddr,
    input  wire [7:0] wdata,
    input  wire [1:0] raddr,
    output wire [7:0] rdata
);
    reg [7:0] mem [0:3];
    integer i;

    initial begin
        for (i = 0; i < 4; i = i + 1) mem[i] = 8'd0;
    end

    always @(posedge clk) begin
        if (we) mem[waddr] <= wdata;
    end

    assign rdata = mem[raddr];
endmodule