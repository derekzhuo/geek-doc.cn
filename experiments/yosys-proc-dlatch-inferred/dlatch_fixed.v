// 修复版：补全 else 分支，组合逻辑每个路径都有赋值，不再推断锁存器
module dlatch_fixed (
    input  wire       en,
    input  wire [7:0] d,
    output reg  [7:0] q
);

    always @(*) begin
        if (en)
            q = d;
        else
            q = 8'h00;   // 补全分支：en 为 0 时 q 有确定值
    end

endmodule
