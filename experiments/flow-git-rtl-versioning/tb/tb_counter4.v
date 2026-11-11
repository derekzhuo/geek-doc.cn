`timescale 1ns/1ps
module tb_counter4;
  reg clk = 0;
  reg rst_n = 0;
  reg en = 1;
  wire [3:0] q;
  wire carry;
  counter4 dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q), .carry(carry));
  always #5 clk = ~clk;
  initial begin
    $dumpfile("build/wave.vcd");
    $dumpvars(0, tb_counter4);
    #12 rst_n = 1;
    @(posedge clk); #1; en = 0;     // 暂停 4 拍，q 保持
    repeat (4) @(posedge clk); #1;
    if (q !== 4'd1) $display("TEST FAIL hold q=%0d", q);
    en = 1;                          // 恢复计数
    repeat (14) @(posedge clk); #1;
    if (q !== 4'd15 || carry !== 1'b1)
      $display("TEST FAIL count q=%0d carry=%b", q, carry);
    else begin
      @(posedge clk); #1;
      if (q !== 4'd0) $display("TEST FAIL wrap q=%0d", q);
      else           $display("TEST PASS tb_counter4");
    end
    #10 $finish;
  end
endmodule
