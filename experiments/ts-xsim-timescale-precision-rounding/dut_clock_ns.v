`timescale 1ns/1ns

module dut_clock (
  input  wire clk,
  output reg  q
);

  initial begin
    q = 1'b0;
  end

  always #1.234 begin
    q = ~q;
  end

endmodule
