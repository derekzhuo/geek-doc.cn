// 修复版：内层循环变量改名 bit_i，不再遮蔽模块级 i
module varhidden_fixed (
    input  wire        clk,
    input  wire [7:0]  din,
    output reg  [7:0]  dout
);

    integer i;              // 模块级 i，用作移位计数
    reg [7:0] acc;

    always @(posedge clk) begin
        acc <= acc ^ din;
        // 内层作用域使用独立名字 bit_i，与模块级 i 各管各的
        for (int bit_i = 0; bit_i < 8; bit_i = bit_i + 1) begin
            dout[bit_i] <= din[7 - bit_i];
        end
        if (i < 4)
            i <= i + 1;
        else
            i <= 0;
    end

endmodule
