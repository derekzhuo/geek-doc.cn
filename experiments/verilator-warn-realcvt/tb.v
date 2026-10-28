// 误差演示：同一输入 100，real 版输出 369（3.7*100=370 期望 370，实际截断偏差）
`timescale 1ns/1ps
module tb;
  reg  [15:0] in_sample;
  wire [15:0] out_bad;
  wire [15:0] out_fixed;

  gain_bad   u_bad   (.in_sample(in_sample), .out_sample(out_bad));
  gain_fixed u_fixed (.in_sample(in_sample), .out_sample(out_fixed));

  initial begin
    in_sample = 16'd101;
    #1;
    $display("in=%0d bad(real 3.7)=%0d fixed(Q1.6 x237)=%0d exact=373.7", in_sample, out_bad, out_fixed);
    in_sample = 16'd1000;
    #1;
    $display("in=%0d bad(real 3.7)=%0d fixed(Q1.6 x237)=%0d expect=3700", in_sample, out_bad, out_fixed);
    $finish;
  end
endmodule
