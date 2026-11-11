`timescale 1ps/1ps
module tb_counter;
  reg clk = 0, rst_n = 1, en = 1;
  wire [3:0] q;
  wire carry;
  integer err = 0, cyc = 0;

  counter u_dut (.clk(clk), .rst_n(rst_n), .en(en), .q(q), .carry(carry));

  always #10000 clk = ~clk;  // 周期 20ns

`ifdef GATES
  initial $sdf_annotate("counter.sdf", u_dut);
`endif

  // 打印每次 q / carry 变化的时刻：前仿落在时钟沿，后仿偏离时钟沿
  always @(q or carry)
    $display("t=%0t  q=%0d carry=%b", $time, q, carry);

  // 时钟沿后 1ns 采样：1ns 远大于门级延时，前仿/后仿结果都应已稳定
  always @(posedge clk) begin
        #1000;
    if (rst_n) begin
      cyc = cyc + 1;
      if (q !== cyc[3:0]) begin
        $display("ERROR cyc=%0d q=%0d expect=%0d", cyc, q, cyc[3:0]);
        err = err + 1;
      end
      if (carry !== (cyc[3:0] == 4'd15)) begin
        $display("ERROR cyc=%0d carry=%b expect=%b", cyc, carry, cyc[3:0] == 4'd15);
        err = err + 1;
      end
    end
  end

  initial begin
    $timeformat(-12, 0, " ps", 8);
    #1000 rst_n = 0; #4000 rst_n = 1;  // 1ns 拉低复位，5ns 释放
    repeat (19) @(posedge clk);
    #5000;
    if (err == 0) $display("PASS: %0d cycles checked, final q=%0d", cyc, q);
    else          $display("FAIL: %0d errors", err);
    $finish;
  end
endmodule
