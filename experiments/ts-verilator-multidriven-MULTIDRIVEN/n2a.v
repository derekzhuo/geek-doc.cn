module n2a(input wire clk1, input wire clk2, input wire a, input wire b, output reg y);
  always @(posedge clk1) y <= a;
  always @(posedge clk2) y <= b;
endmodule
