module n2c(input wire clk, input wire a, output wire y);
  reg yr;
  always @(posedge clk) yr <= a;
  assign y = yr;
  assign y = a;
endmodule
