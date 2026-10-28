// 触发 REALCVT：real 字面量隐式转换到整数信号
module gain_bad(
    input  wire [15:0] in_sample,
    output reg  [15:0] out_sample
);
  // 增益系数顺手写成浮点字面量，乘出来是 real，赋回 16bit 整数
  always @* begin
    out_sample = in_sample * 3.7;   // real -> 整数隐式转换，丢小数部分
  end
endmodule
