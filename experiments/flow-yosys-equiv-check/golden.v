// golden 参考实现：带使能的 2-4 译码器
// en=0 时输出全 0；en=1 时按 sel 独热编码
module decoder (
    input  wire [1:0] sel,
    input  wire       en,
    output reg  [3:0] y
);
    always @(*) begin
        y = 4'b0000;
        if (en) begin
            case (sel)
                2'b00:   y = 4'b0001;
                2'b01:   y = 4'b0010;
                2'b10:   y = 4'b0100;
                2'b11:   y = 4'b1000;
            endcase
        end
    end
endmodule
