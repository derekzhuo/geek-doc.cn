// 修复版：显式声明内部信号
`default_nettype none
module implicit_fixed (
    input  wire a,
    input  wire b,
    output wire y
);
  wire sum_ab;            // 显式声明，位宽一目了然
  assign sum_ab = a & b;
  assign y      = sum_ab;
endmodule
`default_nettype wire
