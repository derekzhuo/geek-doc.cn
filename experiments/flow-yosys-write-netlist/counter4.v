// 最小可综合设计：4 位带使能与异步复位的计数器
module counter4 (
    input  wire       clk,
    input  wire       rst_n,   // 低电平有效的异步复位
    input  wire       en,      // 计数使能
    output reg  [3:0] q,
    output wire       carry    // q == 15 且 en 时拉高
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 4'd0;
        else if (en)
            q <= q + 4'd1;
    end

    assign carry = en & (q == 4'd15);
endmodule
