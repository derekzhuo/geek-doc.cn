// 错误3：端口连接问题——位宽不匹配 + 端口悬空未连接
module adder4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [4:0] sum
);
    assign sum = a + b;
endmodule

module top (
    input  wire [3:0] x,
    input  wire [3:0] y,
    output wire [4:0] s
);
    wire [1:0] narrow;   // 只有 2 位，连到 4 位端口 b 触发位宽告警
    adder4 u_add (
        .a   (x),
        .b   (narrow),   // 位宽 2 -> 4，不匹配
        .sum (s)
        // 端口 y 根本没在 top 里用上（输入悬空）
    );
endmodule
