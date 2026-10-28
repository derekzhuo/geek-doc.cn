// 2-to-4 译码器：组合逻辑，但敏感表只写了 a，漏了 b
module decoder_bug (
    input  wire       a,
    input  wire       b,
    output reg  [3:0] y
);

always @(a) begin          // BUG: 敏感表漏了 b
    case ({a, b})
        2'b00: y = 4'b0001;
        2'b01: y = 4'b0010;
        2'b10: y = 4'b0100;
        2'b11: y = 4'b1000;
    endcase
end

endmodule
