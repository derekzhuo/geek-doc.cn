`timescale 1ns/1ps

module tb_counter;
  reg        clk;
  reg        rst_n;
  wire [3:0] count;

  counter4 dut (
    .clk(clk),
    .rst_n(rst_n),
    .count(count)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 1'b0;
    #12 rst_n = 1'b1;
    repeat (4) @(posedge clk);
    #1;
    if (count === 4'd4)
      $display("INPUT_PATH_SIM_PASS count=%0d", count);
    else
      $display("INPUT_PATH_SIM_FAIL count=%0d", count);
    #4;
    $finish;
  end
endmodule
