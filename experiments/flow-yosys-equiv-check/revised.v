// revised 实现：功能等价的移位写法（先综合再与 golden 比对）
// 4'b0001 << sel 在 sel 为 0/1/2/3 时正好给出独热码
module decoder (
    input  wire [1:0] sel,
    input  wire       en,
    output wire [3:0] y
);
    assign y = en ? (4'b0001 << sel) : 4'b0000;
endmodule
