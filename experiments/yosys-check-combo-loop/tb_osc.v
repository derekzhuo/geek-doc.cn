`timescale 1ns/1ps
module tb_osc;
  reg en = 1'b0;   // 先让环路稳定（en=0 时 a=1、c=1）
  wire y;
  loop_osc u(.en(en), .y(y));
  initial begin
    #100 en = 1'b1;          // 第 100ns 打开环路，反相环开始零时延振荡
    #900;
    $display("sim reached 1000ns: y=%b", y);
    $finish;
  end
endmodule
