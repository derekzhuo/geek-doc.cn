// 故意制造 VARHIDDEN：内层 for 循环变量 i 遮蔽模块级 i
module varhidden_bad (
    input  wire        clk,
    input  wire [7:0]  din,
    output reg  [7:0]  dout
);

    integer i;              // 模块级 i，用作移位计数
    reg [7:0] acc;

    always @(posedge clk) begin
        acc <= acc ^ din;
        // 内层作用域又声明了一个同名 i，遮蔽了模块级的 i
        for (int i = 0; i < 8; i = i + 1) begin
            dout[i] <= din[7 - i];
        end
        // 这里引用的 i 是模块级 i，与循环里的 i 不是同一个变量
        if (i < 4)
            i <= i + 1;
        else
            i <= 0;
    end

endmodule
