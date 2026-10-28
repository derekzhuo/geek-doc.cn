// 修复版：always @(*) 自动推导完整敏感表
module decoder_fix (
    input  wire       a,
    input  wire       b,
    output reg  [3:0] y
);

always @(*) begin          // FIX: 由工具推导完整敏感表
    case ({a, b})
        2'b00: y = 4'b0001;
        2'b01: y = 4'b0010;
        2'b10: y = 4'b0100;
        2'b11: y = 4'b1000;
    endcase
end

endmodule
