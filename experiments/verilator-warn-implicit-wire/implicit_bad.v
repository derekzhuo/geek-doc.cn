// 复现 %Warning-IMPLICIT：驱动一个从未声明的信号
module implicit_bad (
    input  wire a,
    input  wire b,
    output wire y
);
  // sum_ab 从未声明，Verilog 默认把它当 1-bit wire
  assign sum_ab = a & b;
  assign y      = sum_ab;
endmodule
