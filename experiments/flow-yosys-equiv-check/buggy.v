// buggy 实现：故意改错——禁止时输出 0001 而不是 0000
module decoder (
    input  wire [1:0] sel,
    input  wire       en,
    output wire [3:0] y
);
    assign y = en ? (4'b0001 << sel) : 4'b0001;
endmodule
