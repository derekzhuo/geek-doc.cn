// 8 位带使能与同步复位的计数器：eda-lab yosys 实验样例
module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [7:0] count,
    output wire       overflow
);
    always @(posedge clk) begin
        if (!rst_n)
            count <= 8'd0;
        else if (en)
            count <= count + 8'd1;
    end

    assign overflow = &count;  // 全 1 时溢出
endmodule
