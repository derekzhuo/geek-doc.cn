// 行为差异演示：同一时钟沿，另一个 always 块采样 cnt
// 混赋版（复位用 =）：采样块可能当拍就看到复位后的 0（事件顺序依赖）
// 全 <= 版：采样块当拍只能看到旧值 X，行为确定
`timescale 1ns/1ps
module tb_race;
  reg clk = 0;
  reg rst_n = 0;
  wire [7:0] cnt_bad;
  wire [7:0] cnt_fixed;

  blkandnblk_bad   dut_bad  (.clk(clk), .rst_n(rst_n), .cnt(cnt_bad));
  blkandnblk_fixed dut_good (.clk(clk), .rst_n(rst_n), .cnt(cnt_fixed));

  always #5 clk = ~clk;

  // 与 DUT 同沿采样：复现读-写竞争
  always @(posedge clk) begin
    $display("t=%0t rst_n=%b bad_sampled=%0d fixed_sampled=%0d",
             $time, rst_n, cnt_bad, cnt_fixed);
  end

  initial begin
    repeat (3) @(posedge clk);
    #1 rst_n = 1;
    repeat (3) @(posedge clk);
    #1 $finish;
  end
endmodule
