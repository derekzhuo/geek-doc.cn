// 坏例子：always 块分支不全，proc_dlatch 推断出锁存器
module dlatch_bad (
    input  wire       en,
    input  wire [7:0] d,
    output reg  [7:0] q
);

    // en 为 0 时 q 没有任何赋值 —— 综合器只能造锁存器保持旧值
    always @(*) begin
        if (en)
            q = d;
    end

endmodule
