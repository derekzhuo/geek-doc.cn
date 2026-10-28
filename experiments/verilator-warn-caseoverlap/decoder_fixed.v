// 修复版：删掉与前面取值重复的 4'b0011 分支
module decoder_fixed (
    input  wire [3:0] sel,
    output reg  [7:0] out
);
    always @(*) begin
        case (sel)
            4'b0000: out = 8'h00;
            4'b0001: out = 8'h11;
            4'b0011: out = 8'h33;   // 0011 只出现一次，重叠消除
            4'b0111: out = 8'h77;
            default: out = 8'hAA;
        endcase
    end
endmodule
