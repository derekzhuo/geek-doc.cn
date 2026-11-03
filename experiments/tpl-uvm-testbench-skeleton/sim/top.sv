`timescale 1ns/1ns
module top;
  dut_if if0();

  dut u_dut (
    .clk      (if0.clk),
    .rst_n    (if0.rst_n),
    .in_valid (if0.in_valid),
    .in_data  (if0.in_data),
    .out_valid(if0.out_valid),
    .out_data (if0.out_data)
  );

  initial begin
    if0.clk = 1'b0;
    forever #5ns if0.clk = ~if0.clk;
  end

  initial begin
    if0.rst_n    = 1'b0;
    if0.in_valid = 1'b0;
    if0.in_data  = 8'd0;
    repeat (3) @(posedge if0.clk);
    if0.rst_n    = 1'b1;
  end

  initial begin
    base_test t;
    @(posedge if0.clk);
    t = new(if0);
    t.run();
  end
endmodule
