module n2b(input wire clk, input wire a, input wire b, output reg y);
  always @(posedge clk) y <= a;
  always @(*) y = b;
endmodule
