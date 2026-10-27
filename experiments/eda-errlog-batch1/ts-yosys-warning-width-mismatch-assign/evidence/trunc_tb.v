`timescale 1ns/1ps
module trunc_tb;
  reg clk = 0;
  reg [7:0] wide = 8'd0;
  wire [3:0] narrow_bad;
  wire [7:0] extended_ok;
  assign narrow_bad = wide;
  assign extended_ok = {4'b0000, wide[3:0]};
  always #5 clk = ~clk;
  always @(negedge clk) begin
    wide <= wide + 8'd1;
    $display("t=%0t wide=%0d (8'h%02h) -> narrow_bad=%0d (4'h%h) extended_ok=%0d", $time, wide, wide, narrow_bad, narrow_bad, extended_ok);
    if (wide >= 8'd20) begin $display("SIM DONE: truncation loss observed when wide > 15"); $finish; end
  end
  initial begin
    $dumpfile("trunc.vcd");
    $dumpvars(0, trunc_tb);
  end
endmodule
