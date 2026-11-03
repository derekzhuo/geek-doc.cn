// 子模块：带使能与异步复位的参数化累加器
module sub #(
    parameter WIDTH = 4
) (
    input               clk,
    input               rst_n,
    input               en,
    input  [WIDTH-1:0]  d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= {WIDTH{1'b0}};
        else if (en)
            q <= q + d;
    end
endmodule
