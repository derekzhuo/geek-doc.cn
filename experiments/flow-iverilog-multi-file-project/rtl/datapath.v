`timescale 1ns/1ps
// 顶层数据通路：regfile 读出操作数 a，alu 与立即数 imm 运算，结果可写回寄存器堆
module datapath (
    input  wire       clk,
    input  wire [1:0] op,
    input  wire [1:0] raddr,
    input  wire [7:0] imm,
    input  wire       we,
    input  wire [1:0] waddr,
    output wire [7:0] result
);
    wire [7:0] a;

    regfile u_regfile (
        .clk(clk), .we(we), .waddr(waddr), .wdata(result),
        .raddr(raddr), .rdata(a)
    );

    alu u_alu (
        .op(op), .a(a), .b(imm), .y(result)
    );
endmodule