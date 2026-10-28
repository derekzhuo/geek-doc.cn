// 定点化修复：增益 3.7 用 Q1.6 定点常数 237 (3.7*64=236.8 取 237)
module gain_fixed(
    input  wire [15:0] in_sample,
    output wire [15:0] out_sample
);
  localparam [7:0] GAIN_Q6 = 8'd237;      // 3.7 的 Q1.6 定点表示
  wire [23:0] prod = in_sample * GAIN_Q6; // 全整数运算，16bit*8bit 最多 24bit
  assign out_sample = prod[21:6];         // 右移 6 位去掉小数刻度
  // 明确告知工具：高位与低位是定点格式里有意丢弃的
  wire _unused_ok = &{1'b0, prod[23:22], prod[5:0], 1'b0};
endmodule
