`timescale 1ns/1ps
`ifndef DUT
`define DUT standard
`endif

module tb;
  reg clk = 0;
  reg rst = 1;
  reg start = 0;
  reg finish = 0;
  wire ready;
  wire done;

  `DUT dut (
    .clk(clk), .rst(rst), .start(start), .finish(finish),
    .ready(ready), .done(done)
  );

  always #5 clk = ~clk;

  task check;
    input expected_ready;
    input expected_done;
    begin
      #1;
      if (ready !== expected_ready || done !== expected_done)
        $fatal(1, "FAIL ready=%b done=%b", ready, done);
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst = 0;
    check(1, 0);

    start = 1;
    @(negedge clk);
    start = 0;
    check(0, 0);

    finish = 1;
    @(negedge clk);
    finish = 0;
    check(0, 1);

    @(negedge clk);
    check(1, 0);
    $display("PASS synthesized netlist");
    $finish;
  end
endmodule
