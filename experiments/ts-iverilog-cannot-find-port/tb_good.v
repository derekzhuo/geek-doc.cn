`timescale 1ns/1ps
module tb_good;
  reg clk;
  reg rst_n;
  reg enable;
  wire [3:0] count;

  counter dut (
      .clk    (clk),
      .rst_n  (rst_n),
      .enable (enable),
      .count  (count)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    enable = 1'b0;

    repeat (2) @(posedge clk);
    #1;
    rst_n = 1'b1;
    enable = 1'b1;

    repeat (3) @(posedge clk);
    #1;
    if (count !== 4'd3) begin
      $display("FAIL count=%0d expected=3", count);
      $finish(1);
    end

    $display("PASS count=%0d", count);
    $finish(0);
  end
endmodule
