// tb.v —— 有 `timescale 的测试台：意图 10ns 翻转一次时钟
`timescale 1ns/1ps

module tb;
  reg clk = 0;
  reg en = 0;
  wire y;

  // 意图：#5 = 5ns，半周期 5ns
  always #5 clk = ~clk;

  dut u_dut (.clk(clk), .en(en), .y(y));

  initial begin
    $display("tb timescale: 1ns/1ps, #5 应为 5ns");
    #12 en = 1;          // 意图：12ns 时使能
    #40 $display("time=%0t y=%b", $time, y);
    #20 $finish;
  end
endmodule
