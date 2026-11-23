`timescale 1ns/1ps

module tb_seq_detector;
  integer errors = 0;
`include "tb_tasks.vh"

  reg  clk = 0;
  reg  rst_n;
  reg  din;
  wire found;

  always #5 clk = ~clk;

  seq_detector_mealy dut (
    .clk(clk), .rst_n(rst_n), .din(din), .found(found)
  );

  // Sample the combinational `found` at negedge: by then the posedge NBA
  // state update and combinational re-evaluation have both settled.
  integer hits = 0;
  always @(negedge clk) begin
    if (found) hits = hits + 1;
  end

  // Drive one bit per clock on negedge with a blocking assignment, so the
  // value is fully stable before the DUT samples it at the next posedge.
  task send_bit(input b);
    begin
      @(negedge clk) din = b;
    end
  endtask

  initial begin
    $dumpfile("lab03-seq-detector-fsm/sim_build/lab03.vcd");
    $dumpvars(0, tb_seq_detector);

    // --- Case 1: a single 1101 inside noise, exactly one detection ---
    rst_n = 0;
    din   = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;

    send_bit(0); send_bit(0); send_bit(1); send_bit(1);
    send_bit(0); send_bit(1); send_bit(0);
    @(negedge clk); #1;
    check_input(hits == 1, "single 1101 pattern detected once");

    // --- Case 2: overlapping 1101101 must produce two detections ---
    hits  = 0;
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;

    send_bit(1); send_bit(1); send_bit(0); send_bit(1);
    send_bit(1); send_bit(0); send_bit(1);
    @(negedge clk); #1;
    check_input(hits == 2, "overlapping 1101101 pattern detected twice");

    // --- Case 3: near-miss 1100 must not detect ---
    hits  = 0;
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;

    send_bit(1); send_bit(1); send_bit(0); send_bit(0);
    @(negedge clk); #1;
    check_input(hits == 0, "near-miss 1100 produces no detection");

    finish_summary(errors);
  end
endmodule
