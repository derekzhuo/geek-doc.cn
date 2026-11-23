`timescale 1ns/1ps

module tb_uart_tx;
  integer errors = 0;
`include "tb_tasks.vh"

  reg        clk = 0;
  reg        rst_n;
  reg        start;
  reg  [7:0] tx_byte;
  wire       tx;
  wire       done;

  always #5 clk = ~clk;

  uart_tx #(.CLKS_PER_BIT(8)) dut (
    .clk(clk), .rst_n(rst_n), .start(start),
    .tx_byte(tx_byte), .tx(tx), .done(done)
  );

  task wait_clks(input integer n);
    integer i;
    begin
      for (i = 0; i < n; i = i + 1) @(posedge clk);
    end
  endtask

  // Kick one frame: pulse start for one clock with the byte already driven.
  task launch_frame(input [7:0] b);
    begin
      tx_byte = b;
      @(posedge clk) start = 1;
      @(posedge clk) start = 0;
    end
  endtask

  // Sample one frame at each bit midpoint and check it against expectation.
  task sample_frame(input [7:0] expect);
    integer j;
    reg [7:0] got;
    begin
      wait (tx == 1'b0);                 // start bit begins
      wait_clks(4);                      // midpoint of start bit
      check_input(tx == 1'b0, "start bit sampled as 0");
      for (j = 0; j < 8; j = j + 1) begin
        wait_clks(8);                    // next bit midpoint, LSB first
        got[j] = tx;
      end
      wait_clks(8);                      // midpoint of stop bit
      check_input(tx == 1'b1, "stop bit sampled as 1");
      check_input(got == expect, "frame decodes back to launched byte");
      wait (done == 1'b1);
      check_input(done == 1'b1, "done pulses at end of frame");
      @(posedge clk); #1;                // let the NBA deassert settle
      check_input(done == 1'b0, "done is a single-cycle pulse");
      check_input(tx == 1'b1, "line returns to idle high");
    end
  endtask

  initial begin
    $dumpfile("lab04-uart-tx/sim_build/lab04.vcd");
    $dumpvars(0, tb_uart_tx);

    rst_n   = 0;
    start   = 0;
    tx_byte = 8'h00;
    wait_clks(2);
    rst_n = 1;
    check_input(tx == 1'b1, "idle line is high after reset");

    // Frame 1: 0x41 = 'A', binary 0100_0001, LSB first on the wire.
    launch_frame(8'h41);
    sample_frame(8'h41);

    // Frame 2: 0xA5 mixes 0/1 bits and proves a second frame starts clean.
    launch_frame(8'hA5);
    sample_frame(8'hA5);

    finish_summary(errors);
  end
endmodule
