// 惯性延迟写法：老 testbench/行为级代码里常见，搬进可综合 RTL 就出问题
module assigndly_bad (
    input  wire clk,
    input  wire a,
    input  wire b,
    output wire y,
    output reg  q
);
    // 场景一：连续赋值带 # 延迟（惯性延迟）
    assign #5 y = a & b;

    // 场景二：过程赋值带 # 延迟
    always @(posedge clk) begin
        q <= #10 (a | b);
    end
endmodule
