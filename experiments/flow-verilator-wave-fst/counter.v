// counter.v —— 最小可综合设计：8 位带使能计数器
`timescale 1ns/1ps
module counter #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             en,
    output reg  [WIDTH-1:0] cnt,
    output wire             co
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= {WIDTH{1'b0}};
        else if (en)
            cnt <= cnt + 1'b1;
    end

    assign co = (cnt == {WIDTH{1'b1}}) & en;
endmodule
