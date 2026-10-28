// 子模块：8 位数据端口
module adder8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] sum
);
    assign sum = a + b;
endmodule
